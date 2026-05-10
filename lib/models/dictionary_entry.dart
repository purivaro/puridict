import 'dart:convert';

class DictionaryEntry {
  final String id;
  final String headword;
  final int? homonymIndex;
  final List<String> pos;
  final String? categoryFull;
  final String? genderFull;
  final String? context;
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
  final bool incomplete;

  DictionaryEntry({
    required this.id,
    required this.headword,
    this.homonymIndex,
    this.pos = const [],
    this.categoryFull,
    this.genderFull,
    this.context,
    this.glossTh = '',
    this.meaningsOriginal,
    this.etymology,
    this.vigraha,
    this.grammar,
    this.declensionSample,
    this.examples = const [],
    this.seeAlso = const [],
    this.note,
    SourceInfo? source,
    this.incomplete = false,
  }) : source = source ?? const SourceInfo();

  factory DictionaryEntry.fromJson(Map<String, dynamic> j) {
    return DictionaryEntry(
      id: (j['id'] ?? '').toString(),
      headword: (j['headword'] ?? '').toString(),
      homonymIndex: j['homonym_index'] is int ? j['homonym_index'] as int : null,
      pos: _stringList(j['pos']),
      categoryFull: j['category_full'] as String?,
      genderFull: j['gender_full'] as String?,
      context: j['context'] as String?,
      glossTh: (j['gloss_th'] ?? '').toString(),
      meaningsOriginal: j['meanings_original'] as String?,
      etymology: j['etymology'] is Map
          ? Etymology.fromJson(Map<String, dynamic>.from(j['etymology'] as Map))
          : null,
      vigraha: j['vigraha'] as String?,
      grammar: j['grammar'] is Map
          ? Grammar.fromJson(Map<String, dynamic>.from(j['grammar'] as Map))
          : null,
      declensionSample: j['declension_sample'] as String?,
      examples: (j['examples'] is List)
          ? (j['examples'] as List)
              .whereType<Map>()
              .map((e) => Example.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      seeAlso: _stringList(j['see_also']),
      note: j['note'] as String?,
      source: j['source'] is Map
          ? SourceInfo.fromJson(Map<String, dynamic>.from(j['source'] as Map))
          : const SourceInfo(),
      incomplete: j['incomplete'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'headword': headword,
        if (homonymIndex != null) 'homonym_index': homonymIndex,
        'pos': pos,
        if (categoryFull != null) 'category_full': categoryFull,
        if (genderFull != null) 'gender_full': genderFull,
        if (context != null) 'context': context,
        'gloss_th': glossTh,
        if (meaningsOriginal != null) 'meanings_original': meaningsOriginal,
        if (etymology != null) 'etymology': etymology!.toJson(),
        if (vigraha != null) 'vigraha': vigraha,
        if (grammar != null) 'grammar': grammar!.toJson(),
        if (declensionSample != null) 'declension_sample': declensionSample,
        'examples': examples.map((e) => e.toJson()).toList(),
        'see_also': seeAlso,
        if (note != null) 'note': note,
        'source': source.toJson(),
        'incomplete': incomplete,
      };

  /// แสดง pos/cat เป็น chip แรก เช่น "ก." / "น."
  String? get primaryPos => pos.isNotEmpty ? pos.first : null;

  /// Parse suffix วิภัตติ จาก meanings_original สำหรับกิริยา
  /// คืน VibhattiSuffix(part, name) เช่น ("สฺสติ", "วิภัตติ") — null ถ้าหาไม่เจอ
  VibhattiSuffix? parseVibhattiSuffix() {
    if (categoryFull != 'กิริยา') return null;
    final src = meaningsOriginal;
    if (src == null || src.isEmpty) return null;
    final m = RegExp(r'\+\s*(\S+)\s+(\S*วิภัตติ)').firstMatch(src);
    if (m == null) return null;
    return VibhattiSuffix(part: m.group(1)!, name: m.group(2)!);
  }

  /// คืน verb root จาก etymology.verb_root โดยตรง
  EffectiveVerbRoot? get effectiveVerbRoot {
    final ety = etymology;
    if (ety == null) return null;
    final root = ety.verbRoot;
    if (root == null || root.isEmpty) return null;
    return EffectiveVerbRoot(root: root, meaning: ety.verbRootMeaning);
  }

  static List<String> _stringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}

class Etymology {
  final String? verbRoot;
  final String? verbRootMeaning;
  final List<String> paccaya;
  final List<EtymologyComponent> components;
  final String? formationNotes;

  const Etymology({
    this.verbRoot,
    this.verbRootMeaning,
    this.paccaya = const [],
    this.components = const [],
    this.formationNotes,
  });

  factory Etymology.fromJson(Map<String, dynamic> j) => Etymology(
        verbRoot: j['verb_root'] as String?,
        verbRootMeaning: j['verb_root_meaning'] as String?,
        paccaya: DictionaryEntry._stringList(j['paccaya']),
        components: (j['components'] is List)
            ? (j['components'] as List)
                .whereType<Map>()
                .map((e) => EtymologyComponent.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        formationNotes: j['formation_notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (verbRoot != null) 'verb_root': verbRoot,
        if (verbRootMeaning != null) 'verb_root_meaning': verbRootMeaning,
        'paccaya': paccaya,
        'components': components.map((c) => c.toJson()).toList(),
        if (formationNotes != null) 'formation_notes': formationNotes,
      };
}

class EtymologyComponent {
  final String? part;
  final String? role;
  final String? meaning;
  final String? note;

  const EtymologyComponent({this.part, this.role, this.meaning, this.note});

  factory EtymologyComponent.fromJson(Map<String, dynamic> j) =>
      EtymologyComponent(
        part: j['part'] as String?,
        role: j['role'] as String?,
        meaning: j['meaning'] as String?,
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (part != null) 'part': part,
        if (role != null) 'role': role,
        if (meaning != null) 'meaning': meaning,
        if (note != null) 'note': note,
      };
}

class Grammar {
  final String? compoundType;
  final String? saadhana;

  const Grammar({this.compoundType, this.saadhana});

  factory Grammar.fromJson(Map<String, dynamic> j) => Grammar(
        compoundType: j['compound_type'] as String?,
        saadhana: j['saadhana'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (compoundType != null) 'compound_type': compoundType,
        if (saadhana != null) 'saadhana': saadhana,
      };
}

class Example {
  final String? caseName;
  final String? form;
  final String? glossTh;

  const Example({this.caseName, this.form, this.glossTh});

  factory Example.fromJson(Map<String, dynamic> j) => Example(
        caseName: j['case'] as String?,
        form: j['form'] as String?,
        glossTh: j['gloss_th'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (caseName != null) 'case': caseName,
        if (form != null) 'form': form,
        if (glossTh != null) 'gloss_th': glossTh,
      };
}

class SourceInfo {
  final String? volumes;
  final int? page;
  final int? pdfPage;
  final dynamic originalId;

  const SourceInfo({this.volumes, this.page, this.pdfPage, this.originalId});

  factory SourceInfo.fromJson(Map<String, dynamic> j) => SourceInfo(
        volumes: j['volumes'] as String?,
        page: j['page'] is int ? j['page'] as int : null,
        pdfPage: j['pdf_page'] is int ? j['pdf_page'] as int : null,
        originalId: j['original_id'],
      );

  Map<String, dynamic> toJson() => {
        if (volumes != null) 'volumes': volumes,
        if (page != null) 'page': page,
        if (pdfPage != null) 'pdf_page': pdfPage,
        if (originalId != null) 'original_id': originalId,
      };
}

class VibhattiSuffix {
  final String part;
  final String name;
  const VibhattiSuffix({required this.part, required this.name});
}

class EffectiveVerbRoot {
  final String root;
  final String? meaning;
  const EffectiveVerbRoot({required this.root, this.meaning});
}

/// Helper: decode `data_json` column ออกเป็น DictionaryEntry
DictionaryEntry decodeEntryFromDataJson(String dataJson) {
  return DictionaryEntry.fromJson(
      jsonDecode(dataJson) as Map<String, dynamic>);
}
