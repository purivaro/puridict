import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:puridict/services/dictionary_service.dart';

/// ทดสอบท่ออัปเดตข้อมูลออนไลน์ของจริง — ยิงจากเซิร์ฟเวอร์ปลอมในเครื่อง
///
/// สิ่งที่ต้องพิสูจน์ (ไม่ใช่แค่ "โค้ดคอมไพล์ผ่าน"):
///   1. ของดี       → โหลดมาทับแล้วค้นต่อได้ · เวอร์ชันขยับ · เก็บกวาดไฟล์สำรอง
///   2. โหลดไม่ครบ  → sha ไม่ตรง ต้องไม่ทับ · ข้อมูลเดิมยังค้นได้
///   3. ของไม่ใช่ฐาน → sha ตรงแต่เปิดไม่ได้ ต้องไม่ทับเช่นกัน
///
/// รัน: flutter test integration_test/data_update_test.dart -d <device> \
///        --dart-define=DATA_MANIFEST_URL=http://127.0.0.1:8099/manifest.json
///
/// ต้องส่ง DATA_MANIFEST_URL ให้ตรงกับพอร์ตข้างล่าง ไม่งั้นแอพจะไปถาม GitHub จริง
const int _port = 8099;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;

  /// bytes ที่เสิร์ฟที่ /forms.gz กับ manifest ที่จะตอบ — เปลี่ยนได้รายเทสต์
  /// ต้องมีค่าตั้งต้น เพราะแอพยิงถาม manifest เองตั้งแต่ตอนสร้าง service
  List<int> served = const [];
  Map<String, dynamic> manifest = const {};

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
    server.listen((req) async {
      if (req.uri.path == '/manifest.json') {
        req.response
          ..headers.contentType = ContentType.json
          ..write(json.encode(manifest));
      } else {
        req.response
          ..headers.contentLength = served.length
          ..add(served);
      }
      await req.response.close();
    });
  });

  tearDownAll(() => server.close(force: true));

  Future<String> formsPath() async =>
      '${(await getApplicationDocumentsDirectory()).path}/forms.sqlite';

  /// ค้นคำผัน "ราชา" ผ่านทางเดียวกับที่หน้าจอใช้ — ได้กล่องสะพานไหม
  Future<bool> canLookupInflected(DictionaryService s) async {
    s.setSearchQuery('ราชา');
    await s.performSearch();
    return s.inflected != null;
  }

  /// service ที่พร้อมใช้ และ "ยังไม่ได้เช็คอัปเดต"
  /// (ตั้งเวลาเช็คล่าสุดเป็นตอนนี้ เพื่อไม่ให้รอบอัตโนมัติตอนเปิดแอพมาชนกับเทสต์)
  Future<DictionaryService> freshService() async {
    SharedPreferences.setMockInitialValues({
      'data_last_check_at': DateTime.now().millisecondsSinceEpoch,
    });
    final s = DictionaryService();
    await s.loadDictionary();
    // คลังคำผันเป็น lazy — ค้นหนึ่งครั้งเพื่อให้แตกไฟล์จาก bundle ออกมาก่อน
    expect(await canLookupInflected(s), isTrue,
        reason: 'ยังไม่อัปเดตก็ต้องค้นได้อยู่แล้ว');
    return s;
  }

  Future<Map<String, dynamic>> manifestFor(List<int> bytes, String version) async =>
      {
        'datasets': {
          'forms': {
            'version': version,
            'size': bytes.length,
            'sha256': sha256.convert(bytes).toString(),
            'url': 'http://127.0.0.1:$_port/forms.gz',
          }
        }
      };

  Future<List<int>> bundledFormsGz() async =>
      (await rootBundle.load('assets/data/forms.sqlite.gz')).buffer.asUint8List();

  testWidgets('ของดี: โหลดมาทับแล้วค้นคำผันได้ตามปกติ', (tester) async {
    final service = await freshService();

    final gz = await bundledFormsGz();
    served = gz;
    manifest = await manifestFor(gz, '2999.01.01');

    await service.checkForUpdates(force: true);

    expect(service.updateError, isNull);
    expect(service.dataVersions['forms'], '2999.01.01');
    expect(File('${await formsPath()}.bak').existsSync(), isFalse,
        reason: 'สำเร็จแล้วต้องลบไฟล์สำรองทิ้ง ไม่ปล่อยกินที่เครื่อง');
    expect(await canLookupInflected(service), isTrue,
        reason: 'หลังสลับไฟล์ต้องยังค้นได้');
    service.dispose();
  });

  testWidgets('โหลดไม่ครบ (sha ไม่ตรง): ต้องไม่ทับ ข้อมูลเดิมยังใช้ได้',
      (tester) async {
    final service = await freshService();
    final path = await formsPath();
    final sizeBefore = await File(path).length();

    final gz = await bundledFormsGz();
    served = gz.sublist(0, gz.length - 1024); // จำลองโหลดมาไม่ครบ
    manifest = await manifestFor(gz, '2999.02.02'); // sha ของไฟล์เต็ม

    await service.checkForUpdates(force: true);

    expect(service.updateError, isNotNull, reason: 'ต้องรู้ตัวว่าของที่โหลดมาไม่ถูก');
    expect(service.dataVersions['forms'], isNot('2999.02.02'),
        reason: 'ของเสียห้ามถูกนับว่าอัปเดตแล้ว');
    expect(await File(path).length(), sizeBefore, reason: 'ไฟล์เดิมต้องไม่ถูกแตะ');
    expect(File('$path.bak').existsSync(), isFalse);
    expect(File('$path.new').existsSync(), isFalse,
        reason: 'ไฟล์ชั่วคราวต้องถูกเก็บกวาด');
    expect(await canLookupInflected(service), isTrue,
        reason: 'อัปเดตพลาดแล้วต้องยังค้นได้เหมือนเดิม');
    service.dispose();
  });

  testWidgets('ของไม่ใช่ฐานข้อมูล (sha ตรงแต่เปิดไม่ได้): ต้องไม่ทับ',
      (tester) async {
    final service = await freshService();
    final path = await formsPath();
    final sizeBefore = await File(path).length();

    // ไฟล์ที่คลายได้จริง sha ก็ตรง แต่ไม่ใช่ sqlite — ด่านตรวจก่อนสลับต้องจับได้
    served = gzip.encode(utf8.encode('ไม่ใช่ฐานข้อมูลเลย'));
    manifest = await manifestFor(served, '2999.03.03');

    await service.checkForUpdates(force: true);

    expect(service.updateError, isNotNull);
    expect(service.dataVersions['forms'], isNot('2999.03.03'));
    expect(await File(path).length(), sizeBefore, reason: 'ไฟล์เดิมต้องไม่ถูกแตะ');
    expect(File('$path.new').existsSync(), isFalse);
    expect(await canLookupInflected(service), isTrue);
    service.dispose();
  });
}
