import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:puridict/services/update_service.dart';

void main() {
  group('DataManifest.parseAll', () {
    test('อ่าน manifest หลายคลังได้ครบ', () {
      final j = json.decode('''
        {
          "datasets": {
            "combined": {"version":"2026.08.20","size":7364184,"sha256":"AA","url":"https://x/c.gz"},
            "forms":    {"version":"2026.08.22","size":4136352,"sha256":"bb","url":"https://x/f.gz"}
          },
          "version":"2026.08.20","size":7364184,"sha256":"AA","url":"https://x/c.gz"
        }
      ''') as Map<String, dynamic>;

      final all = DataManifest.parseAll(j);
      expect(all.keys, containsAll(<String>['combined', 'forms']));
      expect(all['forms']!.version, '2026.08.22');
      expect(all['forms']!.url, 'https://x/f.gz');
      // sha เก็บเป็นตัวพิมพ์เล็กเสมอ จะได้เทียบกับที่คำนวณเองได้ตรง ๆ
      expect(all['combined']!.sha256, 'aa');
    });

    test('manifest รูปแบบเดิม (คลังเดียว ไม่มี datasets) = combined', () {
      final j = json.decode(
        '{"version":"2026.05.10","size":10,"sha256":"AB","url":"https://x/c.gz"}',
      ) as Map<String, dynamic>;

      final all = DataManifest.parseAll(j);
      expect(all.length, 1);
      expect(all['combined']!.version, '2026.05.10');
    });

    test('คลังที่ฟิลด์ไม่ครบถูกข้าม ไม่ทำให้คลังอื่นพังไปด้วย', () {
      final j = json.decode('''
        {
          "datasets": {
            "combined": {"version":"2026.08.20","size":1,"sha256":"aa","url":"https://x/c.gz"},
            "forms":    {"version":"2026.08.22","sha256":"bb","url":"https://x/f.gz"},
            "mungkala": {"version":123,"size":1,"sha256":"cc","url":"https://x/m.gz"}
          }
        }
      ''') as Map<String, dynamic>;

      final all = DataManifest.parseAll(j);
      expect(all.keys, ['combined']);
    });

    test('manifest ว่าง = ไม่มีอะไรให้อัปเดต', () {
      expect(DataManifest.parseAll(<String, dynamic>{}), isEmpty);
    });
  });

  group('การเทียบเวอร์ชันแบบวันที่', () {
    // แอพตัดสินใจอัปเดตด้วย String.compareTo ตรง ๆ — รูปแบบ YYYY.MM.DD
    // จึงต้องเรียงตามตัวอักษรแล้วได้ลำดับเวลาเสมอ
    test('ใหม่กว่า/เก่ากว่า/เท่ากัน', () {
      expect('2026.08.22'.compareTo('2026.08.20') > 0, isTrue);
      expect('2026.08.20'.compareTo('2026.08.22') < 0, isTrue);
      expect('2026.08.22'.compareTo('2026.08.22') == 0, isTrue);
      expect('2026.09.01'.compareTo('2026.08.31') > 0, isTrue);
      expect('2027.01.01'.compareTo('2026.12.31') > 0, isTrue);
      // ปล่อยซ้ำวันเดียวกันด้วยลำดับต่อท้าย
      expect('2026.08.22.2'.compareTo('2026.08.22') > 0, isTrue);
    });
  });
}
