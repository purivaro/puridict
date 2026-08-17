import 'package:flutter_test/flutter_test.dart';

import 'package:puridict/models/inflected_info.dart';
import 'package:puridict/models/mungkala_group.dart';

void main() {
  group('MungkalaGroup.paliPieces — แยกคำที่หนังสือเสริม (ในวงเล็บ)', () {
    test('วงเล็บอยู่กลางก้อน', () {
      const g = MungkalaGroup(
          pali: 'อญฺเญ (ชนา) ปญฺญเปนฺติ', thai: 'อ.ชน ท. เหล่าอื่น', count: 1, hits: []);
      final p = g.paliPieces;
      expect(p.map((e) => e.text).join(), 'อญฺเญ (ชนา) ปญฺญเปนฺติ');
      expect(p.where((e) => e.supplied).map((e) => e.text).toList(), ['(ชนา)']);
    });

    test('ทั้งก้อนอยู่ในวงเล็บ', () {
      const g = MungkalaGroup(pali: '(อตฺโถ)', thai: 'อ.อรรถ', count: 1, hits: []);
      expect(g.paliPieces.length, 1);
      expect(g.paliPieces.first.supplied, isTrue);
    });

    test('ไม่มีวงเล็บเลย', () {
      const g = MungkalaGroup(pali: 'มงฺคลํ', thai: 'เป็นมงคล', count: 1, hits: []);
      expect(g.paliPieces.length, 1);
      expect(g.paliPieces.first.supplied, isFalse);
    });
  });

  test('MungkalaGroup.pages — รวมเลขหน้าไม่ให้ซ้ำ', () {
    const g = MungkalaGroup(pali: 'ก', thai: 'ข', count: 3, hits: [
      MungkalaHit(page: 55, kho: 3),
      MungkalaHit(page: 63, kho: 4),
      MungkalaHit(page: 55, kho: 9),
    ]);
    expect(g.pages, [55, 63]);
  });

  group('InflectedInfo.distinctReadings — ตัดการอ่านที่ระบุไม่ครบ', () {
    test('ตัวที่ไม่มีวิภัตติถูกกลืนโดยตัวที่ครบกว่า', () {
      const info = InflectedInfo(surface: 'ราชา', glosses: [], parts: [], readings: [
        InflectedReading(lemma: 'ราช', wordClass: 'nama_nama'),
        InflectedReading(
            lemma: 'ราช',
            wordClass: 'nama_nama',
            vibhatti: 'p1',
            vacana: 'eka',
            linga: 'pu'),
      ]);
      final r = info.distinctReadings;
      expect(r.length, 1);
      expect(r.first.tags, ['นามนาม', 'ปฐมา ๑', 'เอกวจนะ', 'ปุงลิงค์']);
    });

    test('การอ่านที่ต่างกันจริงต้องอยู่ครบ (อตฺตโน = จตุตถี/ฉัฏฐี)', () {
      const info = InflectedInfo(surface: 'อตฺตโน', glosses: [], parts: [], readings: [
        InflectedReading(
            lemma: 'อตฺต', wordClass: 'nama_nama', vibhatti: 'p4', vacana: 'eka'),
        InflectedReading(
            lemma: 'อตฺต', wordClass: 'nama_nama', vibhatti: 'p6', vacana: 'eka'),
      ]);
      expect(info.distinctReadings.length, 2);
    });

    test('การอ่านซ้ำเป๊ะเก็บครั้งเดียว', () {
      const info = InflectedInfo(surface: 'ก', glosses: [], parts: [], readings: [
        InflectedReading(lemma: 'ข', wordClass: 'nibata'),
        InflectedReading(lemma: 'ข', wordClass: 'nibata'),
      ]);
      expect(info.distinctReadings.length, 1);
    });
  });
}
