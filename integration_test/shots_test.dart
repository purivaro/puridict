import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:puridict/main.dart' as app;

/// เก็บภาพหน้าจอจริงไว้ตรวจด้วยตา (ไม่ได้ assert อะไร)
///
/// รัน: flutter test integration_test/shots_test.dart -d <device>
/// ภาพจะไปโผล่ที่ build/screenshots/ ผ่าน convertFlutterSurfaceToImage
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitReady(WidgetTester tester) async {
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      // ต้องรอให้ "ฐานพร้อม" จริง ไม่ใช่แค่ช่องค้นหาโผล่ — ไม่งั้นเทสต์ผ่านแบบฟลุก
      // (เคยเจอ: ค้นก่อนฐานแตกไฟล์เสร็จ แล้วได้หน้า error แต่เทสต์ยังผ่าน)
      final ready = find.byType(TextField).evaluate().isNotEmpty &&
          find.textContaining('ฐานข้อมูล').evaluate().isEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty;
      if (ready) return;
    }
    fail('แอพไม่พร้อม');
  }

  Future<void> search(WidgetTester tester, String word) async {
    await tester.enterText(find.byType(TextField).first, word);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('ค้นหา').first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('เก็บภาพ: สะพานรูปคำผัน + เล่มมังคลัตถทีปนี', (tester) async {
    app.main();
    await waitReady(tester);
    await binding.convertFlutterSurfaceToImage();

    await search(tester, 'ราชา');
    await tester.pump();
    await binding.takeScreenshot('app-inflected-racha');

    await tester.tap(find.text('มังคลัตถ'));
    // changeBook จะค้นซ้ำด้วยคำเดิมทันที ต้องรอให้จบก่อน ไม่งั้นพิมพ์คำใหม่แล้วถูกทับ
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await search(tester, 'มงฺคลํ');
    await tester.pump();
    await binding.takeScreenshot('app-mungkala-mongkalam');
  });
}
