import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// driver มาตรฐานของ integration_test — ต่างจาก `flutter test` เฉย ๆ ที่
/// takeScreenshot จะไม่ถูกเขียนลงไฟล์ ถ้าไม่มี onScreenshot มารับ
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final dir = Directory('build/screenshots')..createSync(recursive: true);
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      stdout.writeln('เขียนภาพ: build/screenshots/$name.png (${bytes.length} ไบต์)');
      return true;
    },
  );
}
