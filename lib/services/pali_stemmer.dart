/// Pali stemmer & sandhi rules — port จาก search.php (PHP regex)
///
/// ใช้สำหรับสร้าง candidate stems จากคำที่ผู้ใช้ค้น
/// เพื่อให้ค้นเจอคำในพจนานุกรมที่เป็น stem (ปุริโส → ปุริส)
/// และคืนรูปก่อนสนธิ (ภวตีติ → ภวติ)
class _Rule {
  final RegExp re;
  final String to; // อาจมี $1 = group 1
  const _Rule(this.re, this.to);
}

List<_Rule> _rules(List<List<String>> raw) =>
    raw.map((p) => _Rule(RegExp(p[0]), p[1])).toList(growable: false);

class PaliStemmer {
  // ── อิติ sandhi (–อิติ → contracted) ────────────────────────
  static final List<_Rule> _itiRules = _rules([
    [r'ีติ$', 'ิ'],
    [r'ูติ$', 'ุ'],
    [r'าติ$', ''],
    [r'เติ$', 'เ'],
    [r'โติ$', 'โ'],
    [r'ออติ$', 'อ'],
  ]);

  // ── เอว sandhi (–เอว / –เยว / –เนว particle) ───────────────
  static final List<_Rule> _evaRules = _rules([
    [r'เอวเมว$', 'เอวํ'],
    [r'ตมเมว$', 'ตมํ'],
    [r'ตํเมว$', 'ตํ'],
    [r'สเมว$', 'สํ'],
    [r'เตว$', 'ติ'],
    [r'เสว$', 'สิ'],
    [r'เมว$', 'มิ'],
    [r'เถว$', 'ถิ'],
    [r'นฺเตว$', 'นฺติ'],
    [r'เนว$', 'นิ'],
    [r'เรว$', 'ริ'],
    [r'เลว$', 'ลิ'],
    [r'เกว$', 'กิ'],
    [r'เหว$', 'หิ'],
    [r'เทว$', 'ทิ'],
    [r'เตเยว$', 'ต'],
    [r'เตเหว$', 'ต'],
    [r'สฺเสว$', 'สฺส'],
    [r'นฺเนว$', 'นฺน'],
    [r'มฺเหว$', 'มฺห'],
    [r'([าิีุูเโออ])เยว$', r'$1'],
    [r'([าิีุูเโออ])เหว$', r'$1'],
    [r'([าิีุูเโออ])เสว$', r'$1'],
    [r'([าิีุูเโออ])เนว$', r'$1'],
    [r'ทฺเทว$', 'ท'],
    [r'รฺเรว$', 'ร'],
    [r'เอว$', ''],
    [r'เยว$', ''],
    [r'เหว$', ''],
    [r'เนว$', ''],
    [r'เสว$', ''],
  ]);

  // ── อปิ sandhi (–ปิ particle) ──────────────────────────────
  static final List<_Rule> _apiRules = _rules([
    [r'นาปิ$', 'น'], [r'ราปิ$', 'ร'], [r'ลาปิ$', 'ล'], [r'ตาปิ$', 'ต'],
    [r'ปาปิ$', 'ป'], [r'สาปิ$', 'ส'], [r'มาปิ$', 'ม'], [r'ยาปิ$', 'ย'],
    [r'วาปิ$', 'ว'], [r'กาปิ$', 'ก'], [r'ทาปิ$', 'ท'], [r'ธาปิ$', 'ธ'],
    [r'โกปิ$', 'โก'], [r'โชปิ$', 'โช'], [r'โญปิ$', 'โญ'], [r'โตปิ$', 'โต'],
    [r'โนปิ$', 'โน'], [r'โปปิ$', 'โป'], [r'โมปิ$', 'โม'], [r'โยปิ$', 'โย'],
    [r'โรปิ$', 'โร'], [r'โลปิ$', 'โล'], [r'โสปิ$', 'โส'], [r'โวปิ$', 'โว'],
    [r'เตปิ$', 'เต'], [r'เนปิ$', 'เน'], [r'เรปิ$', 'เร'], [r'เลปิ$', 'เล'],
    [r'เสปิ$', 'เส'], [r'เมปิ$', 'เม'], [r'เยปิ$', 'เย'], [r'เวปิ$', 'เว'],
    [r'เกปิ$', 'เก'], [r'เทปิ$', 'เท'], [r'เธปิ$', 'เธ'], [r'เหปิ$', 'เห'],
    [r'ปิ$', ''],
  ]);

  // ── declension / verbal endings (~80 patterns) ─────────────
  static final List<_Rule> _declRules = _rules([
    // โ + พยัญชนะ → พยัญชนะ (paṭhamā ekap. masc -a stem)
    [r'โก$', 'ก'], [r'โข$', 'ข'], [r'โค$', 'ค'], [r'โฆ$', 'ฆ'], [r'โง$', 'ง'],
    [r'โจ$', 'จ'], [r'โฉ$', 'ฉ'], [r'โช$', 'ช'], [r'โซ$', 'ซ'], [r'โฌ$', 'ฌ'],
    [r'โญ$', 'ญ'], [r'โฎ$', 'ฎ'], [r'โฏ$', 'ฏ'], [r'โฐ$', 'ฐ'], [r'โฑ$', 'ฑ'],
    [r'โฒ$', 'ฒ'], [r'โณ$', 'ณ'], [r'โด$', 'ด'], [r'โต$', 'ต'], [r'โถ$', 'ถ'],
    [r'โท$', 'ท'], [r'โธ$', 'ธ'], [r'โน$', 'น'], [r'โบ$', 'บ'], [r'โป$', 'ป'],
    [r'โผ$', 'ผ'], [r'โพ$', 'พ'], [r'โภ$', 'ภ'], [r'โม$', 'ม'], [r'โย$', 'ย'],
    [r'โร$', 'ร'], [r'โล$', 'ล'], [r'โว$', 'ว'], [r'โศ$', 'ศ'], [r'โษ$', 'ษ'],
    [r'โส$', 'ส'], [r'โห$', 'ห'], [r'โฬ$', 'ฬ'], [r'โอ$', 'อ'],
    // เ-cons-X
    [r'เ(.*)น$', r'$1'],
    [r'านิ$', ''], [r'านิ$', 'า'], [r'ิานิ$', 'ิ'], [r'ุานิ$', 'ุ'],
    [r'นา$', ''], [r'นิ$', ''],
    [r'เ(.*)$', r'$1'],
    [r'า$', ''], [r'ยา$', ''],
    [r'าย$', 'า'], [r'าย$', ''],
    [r'เ(.*)นํ$', r'$1'], [r'เ(.*)หิ$', r'$1'],
    [r'สุ$', ''], [r'เ(.*)สุ$', r'$1'], [r'ีสุ$', 'ี'], [r'ูสุ$', 'ู'],
    [r'ติ$', ''], [r'ริ$', ''], [r'ญา$', ''],
    [r'ํ$', ''], [r'ยํ$', ''],
    [r'สฺส$', ''], [r'สฺมึ$', ''], [r'สฺมา$', ''], [r'มฺหิ$', ''], [r'มฺหา$', ''],
    [r'านํ$', ''], [r'าหิ$', ''], [r'าภิ$', ''], [r'าสุ$', ''],
    [r'ินา$', 'ิ'], [r'ีหิ$', 'ี'], [r'ุนา$', 'ุ'],
    [r'เน$', ''],
    [r'นฺติ$', ''], [r'สิ$', ''], [r'ถ$', ''], [r'มิ$', ''], [r'ม$', ''],
    [r'ตุ$', ''], [r'นฺตุ$', ''], [r'หิ$', ''], [r'าม$', ''],
    [r'นฺโต$', ''], [r'นฺต$', ''],
    [r'มาโน$', ''], [r'มาน$', ''],
    [r'ตฺวา$', ''], [r'ิตฺวา$', ''],
    [r'เจว$', ''], [r'ปิ$', ''], [r'จ$', ''], [r'วา$', ''],
  ]);

  /// แทนที่โดยใช้ regex + replacement (รองรับ \$1)
  static String _replace(String word, _Rule r) {
    if (r.to.contains(r'$1')) {
      return word.replaceFirstMapped(r.re, (m) {
        return r.to.replaceAll(r'$1', m.group(1) ?? '');
      });
    }
    return word.replaceFirst(r.re, r.to);
  }

  /// คืนรูปก่อนสนธิ "อิติ" — เลือกผลลัพธ์ตัวแรกที่ match (ยาว ≥ 3)
  static String processItiSandhi(String w) =>
      _firstMatch(w, _itiRules, minLen: 3);

  /// คืนรูปก่อนสนธิ "เอว"
  static String processEvaSandhi(String w) =>
      _firstMatch(w, _evaRules, minLen: 3);

  /// คืนรูปก่อนสนธิ "อปิ"
  static String processApiSandhi(String w) =>
      _firstMatch(w, _apiRules, minLen: 2);

  static String _firstMatch(
      String word, List<_Rule> rules, {required int minLen}) {
    for (final r in rules) {
      if (r.re.hasMatch(word)) {
        final out = _replace(word, r);
        if (out.length >= minLen) return out;
      }
    }
    return word;
  }

  /// applies declension rules — คืน *ทุก* stem ที่ rule ใดๆ สามารถสร้างได้
  /// (ไม่ใช่แค่ตัวแรกที่ match) เพื่อใช้เป็น search candidates
  static Set<String> declensionStems(String word, {int minLen = 2}) {
    final out = <String>{};
    for (final r in _declRules) {
      if (r.re.hasMatch(word)) {
        final s = _replace(word, r);
        if (s.length >= minLen && s != word) out.add(s);
      }
    }
    return out;
  }

  /// สร้าง candidate stems ทั้งหมดสำหรับการค้น (รวม sandhi + declension)
  /// Limit to [maxCandidates] เพื่อไม่ให้ FTS query ใหญ่เกิน
  static List<String> generateCandidates(String query,
      {int maxCandidates = 20}) {
    final q = query.trim();
    if (q.length < 2) return [q];

    final out = <String>{q};

    // pass 1: sandhi reversal บน query
    final iti = processItiSandhi(q);
    if (iti != q) out.add(iti);
    final eva = processEvaSandhi(q);
    if (eva != q) out.add(eva);
    final api = processApiSandhi(q);
    if (api != q) out.add(api);

    // pass 2: declension stems จากทุกตัวที่มี ณ ตอนนี้
    final seeds = out.toList(growable: false);
    for (final s in seeds) {
      out.addAll(declensionStems(s));
    }

    // pass 3: declension อีกรอบ (เช่น ภวตีติ → ภวติ → ภว)
    final seeds2 = out.toList(growable: false);
    for (final s in seeds2) {
      if (s == q) continue;
      out.addAll(declensionStems(s));
    }

    final list = out.where((s) => s.length >= 2).toList();
    if (list.length <= maxCandidates) return list;
    // ตัดให้พอดี — เก็บ original ไว้แน่นอน
    final trimmed = <String>[q];
    for (final s in list) {
      if (s == q) continue;
      trimmed.add(s);
      if (trimmed.length >= maxCandidates) break;
    }
    return trimmed;
  }

  // ── Thai-side cleaner (สำหรับโหมด ไทย → บาลี) ───────────────
  static const List<String> _thaiMarkers = [
    'อ.', 'ก.', 'ท.', 'ข้าแต่', 'แน่ะ', 'ดูก่อน',
    'ซึ่ง', 'อัน', 'ที่', 'เมื่อ', 'ครั้นเมื่อ', 'ในเพราะ',
    'แต่', 'จาก', 'กว่า', 'เหตุ', 'แห่ง', 'ของ', 'แก่', 'เพื่อ',
    'ต่อ', 'ด้วย', 'โดย', 'ตาม', 'เพราะ', 'มี',
    'ด้วยทั้ง', 'ใน', 'ใกล้', 'เหนือ', 'บน', 'ณ',
  ];

  /// ลบ marker ภาษาไทย (อ., ก., ซึ่ง, อัน, ใน...) ก่อนค้นไทย→บาลี
  static String cleanThaiQuery(String query) {
    var cleaned = query.trim();
    for (final m in _thaiMarkers) {
      // ตัด marker หน้า
      if (cleaned.startsWith(m)) {
        cleaned = cleaned.substring(m.length).trimLeft();
      }
      // ตัด marker ท้าย
      if (cleaned.endsWith(m)) {
        cleaned =
            cleaned.substring(0, cleaned.length - m.length).trimRight();
      }
      // ตัด " marker " กลางประโยค
      cleaned = cleaned.replaceAll(' $m ', ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? query : cleaned;
  }
}
