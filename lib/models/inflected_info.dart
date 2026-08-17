/// ผลจาก "สะพานรูปคำผัน" — คำที่ผู้ใช้ค้นเป็นรูปที่ผันแล้วของศัพท์แม่ตัวไหน
///
/// ทำไมต้องมี: พจนานุกรมเก็บเป็น headword รูปพจนานุกรม แต่ผู้อ่านเจอรูปที่ผันแล้ว
/// ในหนังสือ ("ราชา" พบ 372 ครั้งในธรรมบท แต่ headword คือ "ราช")
/// สะพานบอกได้ทั้งศัพท์แม่ · วิภัตติ/วจนะ/ลิงค์ · ส่วนสนธิ
/// และ **คำแปลที่ยกจากหนังสือจริง** (lex_occurrences 168,069 ชิ้น) พร้อมจำนวนที่พบ
class InflectedReading {
  final String lemma;
  final String? wordClass;
  final String? vibhatti;
  final String? vacana;
  final String? linga;
  final int? dictId;

  const InflectedReading({
    required this.lemma,
    this.wordClass,
    this.vibhatti,
    this.vacana,
    this.linga,
    this.dictId,
  });

  factory InflectedReading.fromRow(Map<String, Object?> r) => InflectedReading(
        lemma: (r['lemma'] as String?) ?? '',
        wordClass: r['word_class'] as String?,
        vibhatti: r['vibhatti'] as String?,
        vacana: r['vacana'] as String?,
        linga: r['linga'] as String?,
        dictId: r['dict_id'] == null ? null : (r['dict_id'] as num).toInt(),
      );

  /// รหัสในฐานเป็นภาษาอังกฤษ/ย่อ — แปลเป็นชื่อที่คนอ่านออกก่อนแสดง
  static const _vib = {
    'p1': 'ปฐมา ๑', 'p2': 'ทุติยา ๒', 'p3': 'ตติยา ๓', 'p4': 'จตุตถี ๔',
    'p5': 'ปัญจมี ๕', 'p6': 'ฉัฏฐี ๖', 'p7': 'สัตตมี ๗', 'alapana': 'อาลปนะ',
  };
  static const _vac = {'eka': 'เอกวจนะ', 'bahu': 'พหุวจนะ'};
  static const _lng = {'pu': 'ปุงลิงค์', 'itth': 'อิตถีลิงค์', 'na': 'นปุงสกลิงค์'};
  static const _cls = {
    'nama_nama': 'นามนาม', 'sabbanama': 'สัพพนาม', 'guna_nama': 'คุณนาม',
    'sankhya': 'สังขยา', 'akhyata': 'กิริยาอาขยาต', 'kiriya_kita': 'กิริยากิตก์',
    'nama_kita': 'นามกิตก์', 'nibata': 'นิบาต', 'upasagga': 'อุปสัค', 'avyaya': 'อัพยยศัพท์',
  };

  List<String> get tags => [
        _cls[wordClass] ?? wordClass,
        _vib[vibhatti],
        _vac[vacana],
        _lng[linga],
      ].whereType<String>().where((s) => s.isNotEmpty).toList(growable: false);
}

/// คำแปลที่ยกจากหนังสือ + จำนวนที่พบทั้ง ๘ ภาค (ใช้เรียงลำดับความสำคัญ)
class AttestedGloss {
  final String gloss;
  final int count;
  const AttestedGloss(this.gloss, this.count);
}

class InflectedInfo {
  final String surface;
  final List<InflectedReading> readings;
  final List<AttestedGloss> glosses;
  final List<String> parts; // ส่วนสนธิ ถ้าเป็นคำสนธิ

  const InflectedInfo({
    required this.surface,
    required this.readings,
    required this.glosses,
    required this.parts,
  });

  bool get isEmpty => readings.isEmpty && glosses.isEmpty;

  /// ตัดการอ่านที่ระบุไม่ครบ เมื่อซ้อนอยู่ในตัวที่ระบุครบกว่าของศัพท์แม่เดียวกัน
  /// (ราช "นามนาม" ซ้อนใน ราช "นามนาม · ปฐมา ๑ · เอกวจนะ · ปุงลิงค์" — ไม่ได้บอกอะไรเพิ่ม)
  List<InflectedReading> get distinctReadings {
    final out = <InflectedReading>[];
    for (final a in readings) {
      if (a.lemma.isEmpty) continue;
      final at = a.tags;
      final covered = readings.any((b) =>
          !identical(b, a) &&
          b.lemma == a.lemma &&
          b.tags.length > at.length &&
          at.every(b.tags.contains));
      if (covered) continue;
      if (out.any((c) => c.lemma == a.lemma && c.tags.join() == at.join())) continue;
      out.add(a);
    }
    return out;
  }
}
