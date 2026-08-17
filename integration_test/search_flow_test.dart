import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:puridict/main.dart' as app;
import 'package:puridict/widgets/inflected_banner.dart';
import 'package:puridict/widgets/mungkala_card.dart';

/// ทดสอบเส้นทางใช้งานจริงบนเครื่อง/ซิมูเลเตอร์
///
/// ครอบสิ่งที่ unit test กับการยิง SQL ตรง ๆ ครอบไม่ได้:
/// พิมพ์คำ → กดค้นหา → หน้าจอขึ้นผลถูกต้องไหม
///
/// รัน: flutter test integration_test/search_flow_test.dart -d <device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// รอให้แอพพร้อม — เปิดครั้งแรกต้องแตกไฟล์ combined.sqlite 64 MB
  /// pumpAndSettle เฉย ๆ จะ timeout จึงต้องวนรอจนช่องค้นหาโผล่
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
    fail('แอพไม่พร้อมภายใน 60 วินาที');
  }

  Future<void> search(WidgetTester tester, String word) async {
    await tester.enterText(find.byType(TextField).first, word);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('ค้นหา').first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('ค้นรูปคำผัน "ราชา" → ขึ้นกล่องสะพาน + ศัพท์แม่ ราช',
      (tester) async {
    app.main();
    await waitReady(tester);

    await search(tester, 'ราชา');

    expect(find.byType(InflectedBanner), findsOneWidget,
        reason: 'ราชา ไม่ใช่ headword จึงต้องขึ้นกล่องสะพาน');
    expect(find.textContaining('เป็นรูปที่ผันแล้ว'), findsOneWidget);
    expect(find.textContaining('ราช'), findsWidgets);
    expect(find.textContaining('หนังสือแปลว่า'), findsOneWidget);
  });

  testWidgets('ค้น "ราช" (เป็น headword เอง) → ต้องไม่ขึ้นกล่องสะพาน',
      (tester) async {
    app.main();
    await waitReady(tester);

    await search(tester, 'ราช');

    expect(find.byType(InflectedBanner), findsNothing,
        reason: 'ราช เป็นรูปพจนานุกรมอยู่แล้ว บอกว่าเป็นรูปผันจะผิด');
  });

  testWidgets('เล่มมังคลัตถทีปนี: ค้น "มงฺคลํ" → ขึ้นการ์ดพร้อมจำนวนที่พบ',
      (tester) async {
    app.main();
    await waitReady(tester);

    await tester.tap(find.text('มังคลัตถ'));
    await tester.pump(const Duration(milliseconds: 400));

    await search(tester, 'มงฺคลํ');

    expect(find.byType(MungkalaCard), findsWidgets);
    expect(find.textContaining('จากมังคลัตถทีปนี'), findsOneWidget);
    expect(find.textContaining('พบ'), findsWidgets);
  });
}
