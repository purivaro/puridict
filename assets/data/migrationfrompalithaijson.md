# Migration: `palithai_dict.json` → `combined.sqlite` / `combined.json`

> เอกสารนี้เขียนสำหรับ AI/นักพัฒนาที่ดูแล **Puri Dict Flutter Mobile App**
> เพื่อให้เข้าใจว่าจะปรับ codebase อย่างไร เมื่อย้ายจากไฟล์ข้อมูลเดิม
> มาเป็นไฟล์ใหม่ที่อยู่ใน `assets/dict/combined/`

---

## 1. สรุปสั้น (TL;DR)

| | เดิม | ใหม่ |
|---|---|---|
| ไฟล์ | `palithai_dict.json` (~7.5 MB) | `combined.sqlite` (~64 MB) + `combined.json` (~33 MB) |
| Schema | array ของ `{word, meanings}` 2 ฟิลด์ | structured entries 20+ ฟิลด์ |
| จำนวน entries | 12,610 | **24,932** |
| Coverage | อรรถกถาธรรมบท ภาค 1-4 เท่านั้น | **ภาค 1-8 ครบทุกภาค** |
| Search | Full-scan in memory | **SQLite + FTS5** indexed |
| ฟิลด์ที่เพิ่ม | – | etymology, examples (declension), vigraha, grammar, see_also, source page, gender, pos, … |

**คำแนะนำหลัก**: เปลี่ยนมาใช้ `combined.sqlite` (ผ่าน `sqflite` / `drift`) แทนการ
parse JSON ทั้งไฟล์เข้า memory จะเร็วขึ้นมาก ใช้ RAM น้อยกว่า เปิดแอปครั้งแรกเร็ว
และค้นหาได้ระดับ FTS5 (รองรับ partial / similar matches) ฟรี

`combined.json` เก็บไว้เป็น fallback หรือสำหรับงานที่ต้องการ scan ทั้ง dataset
(เช่น export, สถิติ) แต่ runtime ไม่ควรโหลดเข้า memory บนมือถือ

---

## 2. โครงสร้างไฟล์ใหม่

### 2.1 `combined.json` (รูปแบบทั้งหมดแบบ pretty)

```json
{
  "metadata": {
    "title": "พจนานุกรมบาลี-ไทย อรรถกถาธรรมบท ภาค 1-8 (รวม)",
    "schema_version": "1.0",
    "extraction_date": "2026-05-09T...",
    "total_entries": 24932,
    "unique_headwords": 19645,
    "sources": [
      { "name": "ภาค 1-4", "entries": 12614 },
      { "name": "ภาค 5-8", "entries": 12318 }
    ]
  },
  "entries": [ /* Entry[] */ ]
}
```

นอกจากนี้ยังมี `combined.jsonl` (line-delimited) สำหรับ stream parsing
หรือ ETL pipeline — รูปแบบ entry เหมือนกันทุกประการ

### 2.2 รูปแบบ `Entry` (canonical)

```jsonc
{
  "id": "v14-6216",                    // unique key (string) — ใช้แทน rowid/PK
  "headword": "ทสฺสติ",                  // คำหลัก (ภาษาบาลี)
  "homonym_index": null,                // 1, 2, ... ถ้าเป็นคำพ้องเสียง

  "source": {
    "volumes": "1-4",                   // "1-4" หรือ "5-8"
    "page": null,                       // เลขหน้าในหนังสือ (อาจ null)
    "pdf_page": null,
    "original_id": 6216
  },

  "pos": ["ก."],                        // ย่อ: น. / ก. / ว. / ปุ. / นปุ. / อิตฺ.
  "category_full": "กิริยา",             // เต็ม: นามนาม / กิริยา / คุณนาม / สัพพนาม ...
  "gender_full": "ปุงลิงค์",             // เพศ (ปุงลิงค์ / อิตฺถีลิงค์ / นปุงสกลิงค์)

  "context": "เช่น ปุคฺคโล อ. บุคคล",     // บริบทของกิริยา (subject)
  "gloss_th": "จักให้, จักถวาย",          // ความหมายไทยกระชับ ★ ใช้แสดงผลหลัก
  "meanings_original": "ก. (เช่น ...) ทา ธาตุ + อ ปัจจัย ...",
                                        // ข้อความต้นฉบับเต็มจากหนังสือ

  "etymology": {                        // โครงสร้างคำ
    "verb_root": "ทา",
    "verb_root_meaning": "ให้",
    "paccaya": ["อ ปัจจัยในกัตตุวาจก"],
    "components": [
      { "part": "ทา", "role": "ธาตุ",  "meaning": "ให้" },
      { "part": "อ",  "role": "ปัจจัย", "note": "ในกัตตุวาจก" }
    ],
    "formation_notes": "..."            // คำอธิบายการประกอบรูป
  },

  "vigraha": "ปตฺตานํ ปุโฏ = ปตฺตปุโฏ",   // บทวิเคราะห์ (สมาส/ตัทธิต)
  "grammar": {
    "compound_type": "วิเสสนบุพพบทกัมมธารยสมาส",
    "saadhana": "..."
  },

  "declension_sample": "ปุริส",          // คำตัวอย่างที่แจกเหมือน
  "examples": [                         // ตัวอย่างการแจกวิภัตติ
    { "case": "ฉ.เอก.", "form": "ทสฺสติสฺส", "gloss_th": "..." }
  ],
  "see_also": ["ทา", "ทตฺวา"],          // คำที่เกี่ยวข้อง

  "note": "ลบ อา ที่ ทา ธาตุ ...",       // หมายเหตุเพิ่มเติม
  "incomplete": false                   // true = ยังขาดข้อมูลบางส่วน
}
```

ฟิลด์ที่อาจไม่มี (null/ไม่มี key) — นามมักไม่มี etymology/examples,
กิริยามักไม่มี gender_full/declension_sample, ฯลฯ ฝั่งแอปต้อง guard ทุกฟิลด์

### 2.3 `combined.sqlite` schema

```sql
CREATE TABLE entries (
    id                TEXT PRIMARY KEY,    -- เช่น "v14-6216" หรือ "v58-p120-002"
    headword          TEXT NOT NULL,
    homonym_index     INTEGER,
    volumes           TEXT,                -- "1-4" หรือ "5-8"
    page              INTEGER,
    pdf_page          INTEGER,
    original_id       INTEGER,
    pos               TEXT,                -- JSON array string เช่น '["น.","ปุ."]'
    category_full     TEXT,
    gender_full       TEXT,
    gloss_th          TEXT,                -- ★ ความหมายหลัก
    meanings_original TEXT,
    etymology_json    TEXT,                -- JSON object string
    grammar_json      TEXT,                -- JSON object string
    vigraha           TEXT,
    declension_sample TEXT,
    examples_json     TEXT,                -- JSON array string
    see_also_json     TEXT,                -- JSON array string
    note              TEXT,
    data_json         TEXT                 -- ★ Entry แบบเต็มในรูป JSON (ตามข้อ 2.2)
);

CREATE INDEX idx_headword ON entries(headword);
CREATE INDEX idx_volumes  ON entries(volumes);
CREATE INDEX idx_page     ON entries(volumes, page);

-- FTS5 full-text index (auto-synced as content='entries')
CREATE VIRTUAL TABLE entries_fts USING fts5(
    id UNINDEXED, headword, gloss_th, meanings_original,
    content='entries', content_rowid='rowid'
);
```

**Tip**: ฟิลด์ `data_json` คือ Entry แบบเต็ม (ตามข้อ 2.2) ที่ serialize แล้ว
ในแอป Flutter ให้ `jsonDecode(row['data_json'])` ครั้งเดียวพอ ไม่ต้อง
ประกอบจากแต่ละ column แยก ๆ — ฟิลด์ column-level อื่นมีไว้สำหรับ
filtering/indexing เร็ว ๆ เท่านั้น

---

## 3. Field mapping ตารางเปรียบเทียบ

| `palithai_dict.json` (เดิม) | `combined` (ใหม่) | หมายเหตุ |
|---|---|---|
| `word` | `headword` | ชื่อฟิลด์เปลี่ยน |
| `meanings` | `gloss_th` (ย่อ) + `meanings_original` (เต็ม) | ของเดิมเป็น "ก้อนเดียว" ของใหม่แยกย่อ/เต็ม |
| – | `pos`, `category_full`, `gender_full` | ใหม่: คำชนิด/เพศ |
| – | `etymology.*` | ใหม่: ธาตุ ปัจจัย บทหน้า |
| – | `vigraha`, `grammar` | ใหม่: บทวิเคราะห์ ประเภทสมาส |
| – | `examples[]` | ใหม่: ตัวอย่างการแจกวิภัตติ |
| – | `see_also[]` | ใหม่: คำที่เกี่ยวข้อง |
| – | `note` | ใหม่: หมายเหตุ |
| – | `source.volumes`, `source.page` | ใหม่: อ้างอิงเล่ม/หน้า |
| – | `id` | ใหม่: unique key เป็น string |

> ของเดิมเก็บแค่ `word + meanings` ความหมายเป็นข้อความก้อนเดียวที่ปนทุกอย่าง
> (คำชนิด, แบบแจก, วิเคราะห์) ของใหม่แยกออกเป็นฟิลด์ structured ทำให้ UI
> สวยขึ้นและ query ได้แม่นกว่า

---

## 4. แนวทางปรับ Flutter app

### 4.1 Asset bundling

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/dict/combined/combined.sqlite
    # combined.json ใส่ก็ต่อเมื่อจำเป็น (กิน RAM/ขนาด APK เพิ่ม ~33 MB)
```

**ขนาดไฟล์**: `combined.sqlite` ~64 MB (uncompressed) — ถ้าต้องการลดขนาด APK
ให้พิจารณา bundling แบบ gzip แล้วขยายตอนเปิดแอปครั้งแรกใส่ app document
directory (ดูตัวอย่างด้านล่าง)

### 4.2 Database setup (sqflite)

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

Future<Database> openDictDb() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = '${dir.path}/combined.sqlite';

  // First run: copy bundled DB out of assets to writable location
  if (!await File(dbPath).exists()) {
    final data = await rootBundle.load('assets/dict/combined/combined.sqlite');
    await File(dbPath).writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  return openDatabase(dbPath, readOnly: true);
}
```

ใช้ `readOnly: true` เพราะ FTS5 index ที่ฝังมาแล้วไม่ต้องเขียนทับ —
เปิดเร็วและประหยัด WAL/journal

### 4.3 Search API ใหม่

หลักการให้ตรงกับ web (`page/dict/api/search_v2.php`): จัด matches เป็น 5 buckets
ตามลำดับความเกี่ยวข้อง

```dart
class DictSearchResult {
  List<DictEntry> exactMatches;     // headword == query
  List<DictEntry> declensionMatches; // คำที่แจกวิภัตติของ query
  List<DictEntry> containsMatches;   // headword LIKE %query%
  List<DictEntry> similarMatches;    // FTS5 fuzzy / prefix
}

Future<DictSearchResult> search(Database db, String query, {String mode = 'pali'}) async {
  // mode: 'pali' = ค้นจาก headword, 'thai' = ค้นจาก gloss_th + meanings_original
  final col = mode == 'pali' ? 'headword' : 'gloss_th';

  // 1) Exact
  final exact = await db.rawQuery(
    'SELECT data_json FROM entries WHERE $col = ? LIMIT 50', [query]);

  // 2) Contains
  final contains = await db.rawQuery(
    'SELECT data_json FROM entries WHERE $col LIKE ? AND $col != ? LIMIT 30',
    ['%$query%', query]);

  // 3) FTS5 similar (รองรับ prefix matching ด้วย *)
  final fts = await db.rawQuery('''
    SELECT e.data_json
      FROM entries_fts f
      JOIN entries e ON e.rowid = f.rowid
     WHERE entries_fts MATCH ?
     LIMIT 30
  ''', ['$query*']);

  return DictSearchResult(
    exactMatches:      exact.map(_decode).toList(),
    declensionMatches: [], // (optional) ใช้ logic แยกถ้าจะรองรับ
    containsMatches:   contains.map(_decode).toList(),
    similarMatches:    fts.map(_decode).toList(),
  );
}

DictEntry _decode(Map<String, Object?> row) =>
    DictEntry.fromJson(jsonDecode(row['data_json'] as String));
```

> **Declension matching** (เช่น พิมพ์ "ปุริสสฺส" แล้วเจอ "ปุริส") เป็น logic
> ที่ซับซ้อนกว่า — ถ้าจำเป็นให้ดู `page/dict/api/search_v2.php` (ฟังก์ชัน
> `findDeclensionMatches`) เป็น reference แล้ว port มาเป็น Dart
> หรือเริ่มแค่ exact + contains + FTS ก่อน ใช้งานจริงก็เพียงพอแล้ว

### 4.4 Entry model

```dart
class DictEntry {
  final String id;
  final String headword;
  final List<String> pos;
  final String? categoryFull;
  final String? genderFull;
  final String glossTh;
  final String? meaningsOriginal;
  final Etymology? etymology;
  final String? vigraha;
  final Grammar? grammar;
  final String? declensionSample;
  final List<Example> examples;
  final List<String> seeAlso;
  final String? note;
  final SourceInfo source;

  factory DictEntry.fromJson(Map<String, dynamic> j) => DictEntry(
    id: j['id'],
    headword: j['headword'],
    pos: List<String>.from(j['pos'] ?? []),
    categoryFull: j['category_full'],
    genderFull: j['gender_full'],
    glossTh: j['gloss_th'] ?? '',
    meaningsOriginal: j['meanings_original'],
    etymology: j['etymology'] != null ? Etymology.fromJson(j['etymology']) : null,
    vigraha: j['vigraha'],
    grammar: j['grammar'] != null ? Grammar.fromJson(j['grammar']) : null,
    declensionSample: j['declension_sample'],
    examples: ((j['examples'] ?? []) as List).map(Example.fromJson).toList(),
    seeAlso: List<String>.from(j['see_also'] ?? []),
    note: j['note'],
    source: SourceInfo.fromJson(j['source'] ?? {}),
  );
}
```

### 4.5 UI: ส่วนที่ต้องปรับ

ของเดิมแสดงแค่ `word` + `meanings` — แอปใหม่ควรแสดงเพิ่ม:

1. **Header**: `headword` + chips (`category_full`, `gender_full`, `pos`)
2. **ความหมายหลัก** (`gloss_th`)
3. **โครงสร้างคำ** — render `etymology.components` เป็น chips (ธาตุ / ปัจจัย / บทหน้า / วิภัตติ) เรียงต่อกันด้วยเครื่องหมาย `+`
4. **บทวิเคราะห์** (`vigraha` + `grammar.compound_type` / `grammar.saadhana`)
5. **การแจกวิภัตติ** (`declension_sample` + `examples[]`)
6. **คำที่เกี่ยวข้อง** (`see_also[]` — คลิกเพื่อค้นต่อ)
7. **หมายเหตุ** (`note`)
8. **ความหมายต้นฉบับ** (`meanings_original` — collapsible)
9. **อ้างอิง**: `ธมฺมปท ภาค {volumes}` (หน้าไม่ต้องแสดง — ตามที่ web ปรับล่าสุด)

> **Reference UI**: ดูได้ที่ web component
> [`page/dict/js/components/ResultCard.js`](../../js/components/ResultCard.js)
> และ [`page/dict/css/puridict.css`](../../css/puridict.css) — โครงสร้าง
> sections/chips ทั้งหมดออกแบบไว้แล้ว นำไปดัดแปลงเป็น Flutter widgets ได้

### 4.6 พิเศษ: การแสดง "วิภัตติ" สำหรับกิริยา

เนื่องจากข้อมูลใหม่เก็บ `verb_root` + `paccaya` แต่ **ไม่ได้แยก suffix
วิภัตติเป็น field ตรง ๆ** ให้ parse จาก `meanings_original` ด้วย regex:

```dart
({String part, String name})? parseVibhattiSuffix(DictEntry e) {
  if (e.categoryFull != 'กิริยา') return null;
  final m = RegExp(r'\+\s*(\S+)\s+(\S*วิภัตติ)').firstMatch(e.meaningsOriginal ?? '');
  if (m == null) return null;
  return (part: m.group(1)!, name: m.group(2)!);
}
```

แล้วเอามาแสดงเป็น chip ตัวสุดท้ายในโครงสร้างคำ (เช่น `ทา ธาตุ + อ ปัจจัย + สฺสติ วิภัตติ`)

---

## 5. ความต่างที่ต้องระวัง

1. **`id` เป็น string ไม่ใช่ int** — เช่น `"v14-6216"` (ภาค 1-4) หรือ
   `"v58-p120-002"` (ภาค 5-8) ห้าม cast เป็น int เด็ดขาด

2. **คำซ้ำ (homonym)** — `unique_headwords = 19,645` แต่ `total_entries = 24,932`
   หมายความว่ามีคำพ้องเสียง ใช้ `homonym_index` แสดงลำดับ

3. **บางฟิลด์เป็น null** — โดยเฉพาะ `page` (ภาค 1-4 ส่วนใหญ่ไม่มี)
   guard ด้วย `?` เสมอ

4. **`gloss_th` vs `meanings_original`** —
   - `gloss_th` = สั้น กระชับ ใช้เป็น "ความหมายหลัก" ที่แสดงใต้ headword
   - `meanings_original` = ข้อความเต็มจากหนังสือ ปนทั้ง ก., นปุ., เป็น...สมาส
     ใช้เป็น "ความหมายต้นฉบับ" ใน collapsible section
   ของเดิม (`palithai_dict.json` field `meanings`) ≈ `meanings_original`

5. **JSON-encoded subfields ใน SQLite** — `etymology_json`, `grammar_json`,
   `examples_json`, `see_also_json`, `pos` ทั้งหมดเก็บเป็น JSON string
   ต้อง `jsonDecode` ก่อนใช้ หรือใช้ `data_json` ทีเดียวจบ

6. **FTS5 tokenizer** — default tokenizer แยกคำที่ space/punctuation
   สำหรับบาลีไทยที่ไม่มี space ใช้ `MATCH 'query*'` (prefix) ปลอดภัยที่สุด
   ถ้าต้องการ similarity ลึกกว่าให้ใช้ `LIKE` แทน

---

## 6. Sample queries

```sql
-- หาคำเป๊ะ
SELECT data_json FROM entries WHERE headword = 'ปาปก';

-- คำขึ้นต้นด้วย "ปาป"
SELECT data_json FROM entries WHERE headword LIKE 'ปาป%' LIMIT 20;

-- FTS5 — ค้นใน headword + ความหมาย
SELECT e.data_json
FROM entries_fts f
JOIN entries e ON e.rowid = f.rowid
WHERE entries_fts MATCH 'ปาปก*'
LIMIT 20;

-- ค้นจากความหมายไทย ("ค้นไทย→บาลี")
SELECT data_json FROM entries
WHERE gloss_th LIKE '%บุญ%'
LIMIT 20;

-- ดึงเฉพาะภาค 5-8
SELECT data_json FROM entries WHERE volumes = '5-8' LIMIT 100;
```

---

## 7. Checklist สำหรับการ migrate

- [ ] วาง `combined.sqlite` ลงใน `assets/dict/combined/`
- [ ] เพิ่ม `assets/dict/combined/combined.sqlite` ใน `pubspec.yaml`
- [ ] เพิ่ม dependency `sqflite` + `path_provider`
- [ ] เขียน `DictDatabase` ที่ copy DB จาก asset → app docs dir แล้วเปิดแบบ readOnly
- [ ] เปลี่ยน data model: `{word, meanings}` → `DictEntry` แบบใหม่ (ดูข้อ 4.4)
- [ ] เปลี่ยน UI ของหน้ารายละเอียดให้รองรับฟิลด์ใหม่ (ดูข้อ 4.5)
- [ ] เปลี่ยน search logic จาก in-memory filter → SQL queries (ดูข้อ 4.3)
- [ ] อัปเดต favorites/history ให้ key ด้วย `id` (string) แทน `word` ลด collision คำพ้อง
- [ ] ทดสอบ: คำที่เคยไม่มีในของเดิม (ภาค 5-8) ต้องเจอแล้ว เช่น `กกุกฏุก`, `กตปตฺตปุฏ`
- [ ] ทดสอบ: คำกิริยาควรแสดง suffix วิภัตติ (เช่น `ทสฺสติ` → ทา + อ + สฺสติ)
- [ ] ลบไฟล์เก่า `palithai_dict.json` ออกจาก assets (ถ้าไม่ใช้แล้ว)

---

## 8. แหล่งอ้างอิง (codebase หลัก)

- API ตัวอย่าง: [`page/dict/api/search_v2.php`](../../api/search_v2.php) — logic การค้นทุก bucket
- Vue component (UI): [`page/dict/js/components/ResultCard.js`](../../js/components/ResultCard.js)
- CSS / design tokens: [`page/dict/css/puridict.css`](../../css/puridict.css)
- หน้าเว็บใช้งานจริง: [`page/dict/puridict.php`](../../puridict.php)

ถ้าสงสัย behavior ควรเทียบกับ web reference ก่อนเสมอ — schema ใหม่นี้เป็น
ของกลางที่ใช้ทั้งฝั่ง web และ mobile เพื่อให้ข้อมูล/พฤติกรรมเหมือนกัน
