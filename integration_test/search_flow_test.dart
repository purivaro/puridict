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
    // ต้องแตะช่องค้นหาก่อนพิมพ์ทุกครั้ง — เหมือนที่ผู้ใช้จริงทำ
    //
    // ถ้าช่องไม่มี focus (เช่น การค้นครั้งก่อนปิดแป้นพิมพ์ไปแล้ว) enterText
    // จะไม่เข้าเงียบ ๆ ช่องยังเป็นคำเก่า แล้วเทสต์ก็ค้นคำเก่าโดยไม่มีใครรู้
    // (เคยหลงคิดว่าแอพมีบั๊ก "สลับเล่มแล้วพิมพ์ไม่เข้า" ทั้งที่เป็นอาการของเทสต์เอง —
    //  วัดแล้ว: ไม่แตะก่อน focus=false พิมพ์ไม่เข้า · แตะก่อน focus=true พิมพ์เข้าปกติ)
    await tester.tap(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, word);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('ค้นหา').first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // ปิดคีย์บอร์ดทุกครั้งหลังค้น
    //
    // แต่ละ testWidgets เรียก app.main() ใหม่ในโปรเซสเดิม แต่ "คีย์บอร์ดจริง"
    // ของเครื่องไม่ได้ถูกปิดตามไปด้วย → เทสต์ตัวถัดไปเริ่มด้วยพื้นที่เหลือแค่ ~350 px
    // แล้วการ์ดผลลัพธ์ล้นขอบ 37 px ทำให้เทสต์ล้มโดยที่แอพไม่ได้ผิดอะไร
    // (พิสูจน์แล้ว: รันเทสต์ที่ล้มนั้นเดี่ยว ๆ ผ่านสบาย ไม่มี overflow เลย)
    FocusManager.instance.primaryFocus?.unfocus();
    for (var i = 0; i < 8; i++) {
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

  testWidgets('เล่มมังคลัตถทีปนี: ค้น "มงฺคลํ" → ขึ้นการ์ด และการ์ดต้องไม่มีสถิติที่พบ',
      (tester) async {
    app.main();
    await waitReady(tester);

    await tester.tap(find.text('มังคลัตถ'));
    await tester.pump(const Duration(milliseconds: 400));

    await search(tester, 'มงฺคลํ');

    expect(find.byType(MungkalaCard), findsWidgets);
    expect(find.textContaining('จากมังคลัตถทีปนี'), findsOneWidget,
        reason: 'หัวข้อผลลัพธ์ยังต้องบอกจำนวนสำนวนที่พบ');

    // ในการ์ดต้องไม่มี "พบ N ที่" กับ "หน้า ..." อีก (หลวงพี่ภูริ 24 ส.ค. 2569)
    // เดิม assert หา 'พบ' เฉย ๆ ซึ่งไปเจอหัวข้อผลลัพธ์ จึงผ่านทั้งที่ไม่ได้ตรวจการ์ดเลย
    for (final card in find.byType(MungkalaCard).evaluate()) {
      final texts = find
          .descendant(of: find.byWidget(card.widget), matching: find.byType(Text))
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .toList();
      expect(texts.any((t) => t.contains('ที่') && t.contains('พบ')), isFalse,
          reason: 'การ์ดไม่ควรมีสถิติ "พบ N ที่" แล้ว');
      expect(texts.any((t) => t.startsWith('หน้า ')), isFalse,
          reason: 'การ์ดไม่ควรมีรายการเลขหน้าแล้ว');
    }
  });
}
