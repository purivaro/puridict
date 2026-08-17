/// คู่ "บาลี–คำแปล" จากมังคลัตถทีปนี พร้อมที่พบในหนังสือ
///
/// หน่วยข้อมูลต่างจากพจนานุกรม: ที่นี่เป็น **ก้อนบาลีอย่างที่หนังสือยกไว้**
/// + คำแปลของก้อนนั้น ไม่ใช่ headword ที่มีชนิดคำ/ลิงค์/วิคหะ
/// จึงเป็นโมเดลและคลังของตัวเอง ไม่ผสมกับ DictionaryEntry
class MungkalaHit {
  final int page;
  final int? kho;
  final String? khoTitle;

  const MungkalaHit({required this.page, this.kho, this.khoTitle});
}

class MungkalaGroup {
  final String pali;   // คงวงเล็บไว้ — วงเล็บ = คำที่หนังสือเสริม/โยคเข้ามา
  final String thai;
  final int count;     // พบสำนวนนี้กี่ที่ในหนังสือ
  final List<MungkalaHit> hits;

  const MungkalaGroup({
    required this.pali,
    required this.thai,
    required this.count,
    required this.hits,
  });

  /// เลขหน้าที่พบ (ไม่ซ้ำ) — แสดงสั้น ๆ ว่า "หน้า 49, 53"
  List<int> get pages {
    final seen = <int>{};
    for (final h in hits) {
      seen.add(h.page);
    }
    return seen.toList(growable: false);
  }

  MungkalaHit? get firstHit => hits.isEmpty ? null : hits.first;

  /// แตกก้อนบาลีเป็นชิ้น ๆ เพื่อทำสีคำในวงเล็บให้ต่างจากบาลีต้นฉบับ
  /// ใช้คลาสเล็กแทน record เพราะ SDK ของโปรเจกต์ยังเป็น <3.0.0 (records ต้อง Dart 3)
  List<PaliPiece> get paliPieces {
    final out = <PaliPiece>[];
    final re = RegExp(r'\(([^)]*)\)');
    var last = 0;
    for (final m in re.allMatches(pali)) {
      if (m.start > last) {
        out.add(PaliPiece(pali.substring(last, m.start), false));
      }
      out.add(PaliPiece(m.group(0)!, true));
      last = m.end;
    }
    if (last < pali.length) out.add(PaliPiece(pali.substring(last), false));
    return out;
  }
}

/// ชิ้นข้อความในก้อนบาลี — [supplied] = อยู่ในวงเล็บ (คำที่หนังสือเสริม/โยคเข้ามา)
class PaliPiece {
  final String text;
  final bool supplied;
  const PaliPiece(this.text, this.supplied);
}
