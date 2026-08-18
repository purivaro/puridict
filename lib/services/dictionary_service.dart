import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:puridict/models/dictionary_entry.dart';
import 'package:puridict/models/inflected_info.dart';
import 'package:puridict/models/mungkala_group.dart';
import 'package:puridict/services/pali_stemmer.dart';
import 'package:puridict/services/update_service.dart';

enum DataUpdateStatus { idle, checking, downloading, applied, error }

class DictionaryService extends ChangeNotifier {
  static const String _assetDbPath = 'assets/data/combined.sqlite.gz';
  static const String _dbFileName = 'combined.sqlite';

  /// ฐานเสริม — คนละไฟล์กับพจนานุกรมโดยเจตนา
  ///   forms    = สะพานรูปคำผัน (สร้างจาก MySQL — คนละแหล่งกับพจนานุกรมที่มาจาก PDF)
  ///   mungkala = คลังศัพท์มังคลัตถทีปนี (คนละหนังสือ คนละหน่วยข้อมูล)
  /// แยกไฟล์ทำให้อัปเดตแต่ละคลังได้อิสระ และไม่กระทบ combined.sqlite ที่ใช้อยู่เดิม
  static const String _assetFormsPath = 'assets/data/forms.sqlite.gz';
  static const String _formsFileName = 'forms.sqlite';
  /// 2 = ข้อมูล 19 ส.ค. 2569 — ซ่อมคำแปลที่ยกจากหนังสือ 2 ชิ้น
  ///     (เลื่อมใน→เลื่อมใส · ภควนฺตํ: ซึ่งพระศาสดา→ซึ่งพระผู้มีพระภาคเจ้า)
  /// เวอร์ชันแยกต่อคลัง จึงแตกไฟล์ใหม่แค่ forms (4 MB) ไม่ต้องแตะ combined (64 MB)
  static const int _assetFormsVersion = 2;
  static const String _assetMkPath = 'assets/data/mungkala.sqlite.gz';
  static const String _mkFileName = 'mungkala.sqlite';
  static const int _assetMkVersion = 1;

  /// bump เมื่ออัปเดตไฟล์ dataset ที่ bundle มา (จะ trigger copy ใหม่)
  static const int _assetDbVersion = 6;

  /// throttle: เช็ค manifest อย่างมาก 1 ครั้งต่อช่วงเวลานี้
  static const Duration _checkInterval = Duration(hours: 6);

  static const String _kRemoteVersion = 'data_remote_version';
  static const String _kLastCheckAt = 'data_last_check_at';

  Database? _db;
  Database? _formsDb;
  Database? _mkDb;

  DataUpdateStatus _updateStatus = DataUpdateStatus.idle;
  double _updateProgress = 0;
  String? _newVersion;
  bool _updateBannerDismissed = false;

  List<DictionaryEntry> _filteredEntries = [];
  List<DictionaryEntry> _favorites = [];
  List<String> _recentSearches = [];
  String _searchQuery = '';
  bool _loading = true;
  bool _searchPerformed = false;
  bool _showRecentSearches = false;
  String _dictionaryType = 'paliThai';
  /// เล่มที่ค้น — ทิศทาง (paliThai/thaiPali) ใช้ร่วมกันทั้งสองเล่ม
  String _book = 'dhammapada';
  InflectedInfo? _inflected;
  List<MungkalaGroup> _mungkalaGroups = [];
  String? _error;
  double _fontSize = 1.2;

  List<DictionaryEntry> get filteredEntries => _filteredEntries;
  List<DictionaryEntry> get favorites => _favorites;
  List<String> get recentSearches => _recentSearches;
  String get searchQuery => _searchQuery;
  bool get loading => _loading;
  bool get searchPerformed => _searchPerformed;
  bool get showRecentSearches => _showRecentSearches;
  String get dictionaryType => _dictionaryType;
  String get book => _book;
  InflectedInfo? get inflected => _inflected;
  List<MungkalaGroup> get mungkalaGroups => _mungkalaGroups;
  String? get error => _error;
  double get fontSize => _fontSize;

  DataUpdateStatus get updateStatus => _updateStatus;
  double get updateProgress => _updateProgress;
  String? get newVersion => _newVersion;
  bool get updateBannerDismissed => _updateBannerDismissed;

  void dismissUpdateBanner() {
    _updateBannerDismissed = true;
    notifyListeners();
  }

  DictionaryService() {
    _init();
  }

  Future<void> _init() async {
    await loadDictionary();
    await loadSettings();
    // background check — ไม่ block UI
    // ignore: discarded_futures
    Future.microtask(checkForUpdates);
  }

  /// Future ของการเปิดฐานครั้งแรก — performSearch รอตัวนี้ได้
  /// เปิดครั้งแรกหลังอัปเดตต้องแตก combined.sqlite 64 MB ใช้เวลาหลายวินาที
  Future<void>? _dbReady;

  Future<void> loadDictionary() {
    return _dbReady ??= _loadDictionaryOnce();
  }

  Future<void> _loadDictionaryOnce() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _db ??= await _openDb();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'ไม่สามารถเปิดฐานข้อมูลพจนานุกรมได้: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<Database> _openDb() =>
      _openBundledDb(_assetDbPath, _dbFileName, _assetDbVersion);

  /// แตกไฟล์ .sqlite.gz จาก asset ครั้งแรก แล้วเปิดแบบอ่านอย่างเดียว
  ///
  /// ทุกคลังใช้ทางเดียวกันหมด (พจนานุกรม · สะพานรูปคำผัน · มังคลัตถทีปนี)
  /// แต่ละคลังมีไฟล์ .version ของตัวเอง — bump version ของคลังไหน ก็แตกใหม่แค่คลังนั้น
  /// ไม่ต้องแตะคลังอื่นที่ผู้ใช้มีอยู่แล้ว (ทั้งสามรวมกันแตกแล้วเกือบ 100 MB)
  Future<Database> _openBundledDb(
      String assetPath, String fileName, int assetVersion) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/$fileName';
    final versionFile = File('${dir.path}/$fileName.version');

    bool needCopy = !await File(dbPath).exists();
    if (!needCopy && await versionFile.exists()) {
      final v = int.tryParse((await versionFile.readAsString()).trim()) ?? 0;
      if (v != assetVersion) needCopy = true;
    } else if (!needCopy) {
      needCopy = true;
    }

    if (needCopy) {
      // ship gzipped (รวมสามคลัง ~15 MB เทียบ 96 MB ถ้าไม่บีบ) — แตกครั้งแรกที่เปิดแอพ
      final data = await rootBundle.load(assetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final decoded = await compute(_gunzip, bytes);
      await File(dbPath).writeAsBytes(decoded, flush: true);
      await versionFile.writeAsString('$assetVersion');
    }

    return openDatabase(dbPath, readOnly: true);
  }

  /// เปิดคลังเสริมแบบ lazy — ผู้ใช้ที่ไม่เคยค้นคำผันหรือไม่เคยเปิดเล่มมังคลัตถทีปนี
  /// จะไม่เสียเวลาแตกไฟล์ 15–17 MB ตอนเปิดแอพ
  /// ล้มเหลวก็คืน null ให้ฟีเจอร์นั้นเงียบไป ไม่ทำให้พจนานุกรมหลักพัง
  Future<Database?> _ensureFormsDb() async {
    if (_formsDb != null) return _formsDb;
    try {
      _formsDb = await _openBundledDb(
          _assetFormsPath, _formsFileName, _assetFormsVersion);
    } catch (e) {
      debugPrint('_ensureFormsDb error: $e');
      return null;
    }
    return _formsDb;
  }

  Future<Database?> _ensureMungkalaDb() async {
    if (_mkDb != null) return _mkDb;
    try {
      _mkDb = await _openBundledDb(_assetMkPath, _mkFileName, _assetMkVersion);
    } catch (e) {
      debugPrint('_ensureMungkalaDb error: $e');
      return null;
    }
    return _mkDb;
  }

  // ─── online dataset updates ──────────────────────────────────

  Future<void> checkForUpdates({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!force) {
        final last = prefs.getInt(_kLastCheckAt) ?? 0;
        final since =
            DateTime.now().millisecondsSinceEpoch - last;
        if (since < _checkInterval.inMilliseconds) return;
      }

      _updateStatus = DataUpdateStatus.checking;
      notifyListeners();

      final manifest = await UpdateService.fetchManifest();
      await prefs.setInt(
          _kLastCheckAt, DateTime.now().millisecondsSinceEpoch);

      if (manifest == null) {
        _updateStatus = DataUpdateStatus.idle;
        notifyListeners();
        return;
      }

      final currentRemote = prefs.getString(_kRemoteVersion);
      if (currentRemote == manifest.version) {
        _updateStatus = DataUpdateStatus.idle;
        notifyListeners();
        return;
      }

      await _applyUpdate(manifest, prefs);
    } catch (e) {
      debugPrint('checkForUpdates error: $e');
      _updateStatus = DataUpdateStatus.error;
      notifyListeners();
    }
  }

  Future<void> _applyUpdate(
      DataManifest manifest, SharedPreferences prefs) async {
    _updateStatus = DataUpdateStatus.downloading;
    _updateProgress = 0;
    _newVersion = manifest.version;
    _updateBannerDismissed = false;
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final gzPath = '${dir.path}/$_dbFileName.gz.new';
    final newDbPath = '${dir.path}/$_dbFileName.new';
    final dbPath = '${dir.path}/$_dbFileName';

    try {
      final ok = await UpdateService.downloadGz(
        url: manifest.url,
        destPath: gzPath,
        onProgress: (p) {
          if (p >= 0) {
            _updateProgress = p;
            notifyListeners();
          }
        },
      );
      if (!ok) throw Exception('download failed');

      final actualSha = await UpdateService.sha256OfFile(gzPath);
      if (actualSha != manifest.sha256) {
        throw Exception('sha256 mismatch: $actualSha vs ${manifest.sha256}');
      }

      // gunzip → newDbPath
      final gzBytes = await File(gzPath).readAsBytes();
      final decoded = await compute(_gunzip, gzBytes);
      await File(newDbPath).writeAsBytes(decoded, flush: true);

      // close old DB, atomic-ish swap, reopen
      await _db?.close();
      _db = null;
      await File(newDbPath).rename(dbPath);
      await File(gzPath).delete().catchError((_) => File(gzPath));
      _db = await openDatabase(dbPath, readOnly: true);

      await prefs.setString(_kRemoteVersion, manifest.version);

      _updateStatus = DataUpdateStatus.applied;
      _updateProgress = 1;
      notifyListeners();
    } catch (e) {
      debugPrint('_applyUpdate error: $e');
      // cleanup partials
      for (final p in [gzPath, newDbPath]) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      // ถ้า DB ปิดไปแล้วแต่ยังไม่ rename → reopen ของเดิม
      _db ??= await openDatabase(dbPath, readOnly: true);
      _updateStatus = DataUpdateStatus.error;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final favoriteJson = prefs.getString('favorites');
    if (favoriteJson != null) {
      try {
        final List<dynamic> list = json.decode(favoriteJson);
        final maps = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _favorites = await _hydrateFavorites(maps);
        // ถ้ามี legacy entry ให้บันทึกรูปแบบใหม่ทับ
        final hasLegacy = maps.any((m) =>
            (m['id'] == null || m['id'].toString().isEmpty) &&
            m['word'] != null);
        if (hasLegacy) {
          await prefs.setString(
              'favorites',
              json.encode(_favorites.map((e) => e.toJson()).toList()));
        }
      } catch (_) {
        _favorites = [];
      }
    }

    final recentJson = prefs.getString('recentSearches');
    if (recentJson != null) {
      try {
        _recentSearches = List<String>.from(json.decode(recentJson));
      } catch (_) {
        _recentSearches = [];
      }
    }

    _fontSize = prefs.getDouble('fontSize') ?? 1.2;

    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void changeDictionaryType(String type) {
    _dictionaryType = type;
    _searchPerformed = false;
    _filteredEntries = [];
    _inflected = null;
    _mungkalaGroups = [];
    notifyListeners();
    // ทิศทางใช้ร่วมกันทั้งสองเล่ม — สลับแล้วยังมีคำค้นอยู่ ให้ค้นซ้ำทันที
    // ไม่งั้นหน้าจะว่างจนผู้ใช้กดค้นเอง ซึ่งดูเหมือนค้นไม่เจอ
    if (_searchQuery.trim().isNotEmpty) {
      // ignore: discarded_futures
      Future.microtask(performSearch);
    }
  }

  /// สลับเล่มที่ค้น — 'dhammapada' (ปทานุกรมธรรมบท) หรือ 'mungkala' (มังคลัตถทีปนี)
  void changeBook(String book) {
    if (_book == book) return;
    _book = book;
    _searchPerformed = false;
    _filteredEntries = [];
    _inflected = null;
    _mungkalaGroups = [];
    notifyListeners();
    if (_searchQuery.trim().isNotEmpty) {
      // ignore: discarded_futures
      Future.microtask(performSearch);
    }
  }

  void toggleRecentSearches() {
    _showRecentSearches = !_showRecentSearches;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredEntries = [];
    _searchPerformed = false;
    _showRecentSearches = false;
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    _showRecentSearches = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentSearches');
    notifyListeners();
  }

  Future<void> changeFontSize(double delta) async {
    _fontSize = (_fontSize + delta).clamp(0.8, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> toggleFavorite(DictionaryEntry entry) async {
    final index = _favorites.indexWhere((fav) => fav.id == entry.id);
    if (index == -1) {
      _favorites.add(entry);
    } else {
      _favorites.removeAt(index);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'favorites', json.encode(_favorites.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  bool isFavorite(DictionaryEntry entry) =>
      _favorites.any((fav) => fav.id == entry.id);

  /// แปลง favorites รูปแบบเดิม `{word, meanings}` → `DictionaryEntry` ใหม่
  /// โดยพยายาม lookup จาก DB ด้วย `headword == word` ก่อน ถ้าไม่เจอจะสร้าง
  /// stub entry (id เริ่มด้วย "legacy-") เพื่อให้ผู้ใช้ไม่เสีย favorites เดิม
  Future<List<DictionaryEntry>> _hydrateFavorites(
      List<Map<String, dynamic>> maps) async {
    final out = <DictionaryEntry>[];
    final seen = <String>{};
    final db = _db;
    for (final m in maps) {
      final hasNewSchema = m['id'] != null && m['headword'] != null;
      if (hasNewSchema) {
        final e = DictionaryEntry.fromJson(m);
        if (seen.add(e.id)) out.add(e);
        continue;
      }
      // legacy: {word, meanings}
      final word = (m['word'] ?? '').toString();
      final meanings = (m['meanings'] ?? '').toString();
      if (word.isEmpty) continue;

      DictionaryEntry? hydrated;
      if (db != null) {
        try {
          final rows = await db.rawQuery(
            'SELECT data_json FROM entries WHERE headword = ? LIMIT 1',
            [word],
          );
          if (rows.isNotEmpty) {
            hydrated = decodeEntryFromDataJson(rows.first['data_json'] as String);
          }
        } catch (_) {}
      }
      hydrated ??= DictionaryEntry(
        id: 'legacy-$word',
        headword: word,
        glossTh: meanings,
      );
      if (seen.add(hydrated.id)) out.add(hydrated);
    }
    return out;
  }

  Future<void> performSearch() async {
    if (_searchQuery.trim().isEmpty) {
      clearSearch();
      return;
    }
    // ฐานยังแตกไฟล์ไม่เสร็จ → รอให้เสร็จก่อน อย่าเด้ง error ใส่ผู้ใช้
    // (พบจากการรันซิมูเลเตอร์: เปิดแอพครั้งแรกหลังอัปเดตแล้วพิมพ์ค้นทันที
    //  จะขึ้น "ฐานข้อมูลยังไม่พร้อม" ทั้งที่แค่ยังโหลดไม่เสร็จ)
    if (_db == null) {
      _loading = true;
      notifyListeners();
      await loadDictionary();
    }
    final db = _db;
    if (db == null) {
      _error = 'ฐานข้อมูลยังไม่พร้อม';
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    final query = _searchQuery.trim();

    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recentSearches', json.encode(_recentSearches));
    }

    _inflected = null;
    _mungkalaGroups = [];

    try {
      if (_book == 'mungkala') {
        // มังคลัตถทีปนีเป็นคลังแยก ผลลัพธ์เป็นคู่บาลี-คำแปล ไม่ใช่ entries
        _mungkalaGroups = await _searchMungkala(query);
        _filteredEntries = [];
      } else {
        _filteredEntries = _dictionaryType == 'paliThai'
            ? await _searchPaliToThai(db, query)
            : await _searchThaiToPali(db, query);
        // สะพานรูปคำผัน — ทำเฉพาะฝั่งบาลีและเฉพาะเมื่อคำที่ค้นไม่ใช่ headword เอง
        // (ถ้าเป็น headword อยู่แล้ว การบอกว่า "เป็นรูปที่ผันแล้ว" จะผิด)
        if (_dictionaryType == 'paliThai') {
          _inflected = await _resolveInflected(db, query);
        }
      }
    } catch (e) {
      _error = 'ค้นหาไม่สำเร็จ: $e';
      _filteredEntries = [];
      _mungkalaGroups = [];
    }

    _searchPerformed = true;
    _loading = false;
    _showRecentSearches = false;
    notifyListeners();
  }

  // ─── สะพานรูปคำผัน ───────────────────────────────────────────

  /// คำที่ค้นเป็นรูปที่ผันแล้วของอะไร + หนังสือแปลว่าอะไร
  ///
  /// คืน null เมื่อ (ก) คำนั้นเป็น headword ของพจนานุกรมเองอยู่แล้ว — บอกว่า
  /// "เป็นรูปที่ผันแล้ว" จะผิด · หรือ (ข) คลังไม่รู้จักรูปนี้
  Future<InflectedInfo?> _resolveInflected(Database db, String query) async {
    final headword = await db.rawQuery(
        'SELECT 1 FROM entries WHERE headword = ? LIMIT 1', [query]);
    if (headword.isNotEmpty) return null;

    final fdb = await _ensureFormsDb();
    if (fdb == null) return null;

    final readings = await fdb.rawQuery(
      'SELECT lemma, word_class, vibhatti, vacana, linga, dict_id '
      'FROM forms WHERE surface = ? ORDER BY is_primary DESC, dict_id IS NULL, rowid',
      [query],
    );
    final glosses = await fdb.rawQuery(
      'SELECT gloss, n FROM form_glosses WHERE surface = ? ORDER BY n DESC LIMIT 8',
      [query],
    );
    final parts = await fdb.rawQuery(
      'SELECT part FROM form_parts WHERE surface = ? ORDER BY pos', [query]);

    if (readings.isEmpty && glosses.isEmpty) return null;

    final info = InflectedInfo(
      surface: query,
      readings: readings.map(InflectedReading.fromRow).toList(growable: false),
      glosses: glosses
          .map((r) => AttestedGloss(
              (r['gloss'] as String?) ?? '', (r['n'] as num?)?.toInt() ?? 0))
          .toList(growable: false),
      parts: parts
          .map((r) => (r['part'] as String?) ?? '')
          .where((p) => p.isNotEmpty)
          .toList(growable: false),
    );
    return info.isEmpty ? null : info;
  }

  // ─── มังคลัตถทีปนี ───────────────────────────────────────────

  /// ค้นคลังมังคลัตถทีปนี — ทิศทางใช้ค่าเดียวกับพจนานุกรม (_dictionaryType)
  Future<List<MungkalaGroup>> _searchMungkala(String query) async {
    final mdb = await _ensureMungkalaDb();
    if (mdb == null) return const [];

    const cols = 'p.pali AS pali, p.thai AS thai, p.seq AS seq, '
        'b.page AS page, b.kho AS kho, b.kho_title AS kho_title';
    List<Map<String, Object?>> rows;

    if (_dictionaryType == 'paliThai') {
      // ค้นรูปคำตรงตัวก่อน (มี index) — ไม่เจอจึงค่อยค้นแบบมีคำนั้นอยู่ในก้อน
      rows = await mdb.rawQuery(
        'SELECT $cols FROM words w JOIN pairs p ON p.id = w.pair_id '
        'JOIN blocks b ON b.block_id = p.block_id '
        'WHERE w.word = ? ORDER BY b.page, p.seq LIMIT 360',
        [_bareWord(query)],
      );
      if (rows.isEmpty) {
        rows = await mdb.rawQuery(
          'SELECT $cols FROM pairs p JOIN blocks b ON b.block_id = p.block_id '
          'WHERE p.pali LIKE ? ORDER BY b.page, p.seq LIMIT 360',
          ['%${_bareWord(query)}%'],
        );
      }
    } else {
      // ค้นจากคำแปลไทยต้องใช้ LIKE ไม่ใช่ FTS — ภาษาไทยไม่มีตัวคั่นคำ
      // tokenizer unicode61 มองคำไทยติดกันเป็น token เดียว ค้น "มงคล" ด้วย FTS ได้ 2 คู่
      // ส่วน LIKE ได้ 182 คู่ และเร็วกว่า (สแกน 54,898 แถว ~10 ms)
      rows = await mdb.rawQuery(
        'SELECT $cols FROM pairs p JOIN blocks b ON b.block_id = p.block_id '
        'WHERE p.thai LIKE ? ORDER BY b.page, p.seq LIMIT 360',
        ['%$query%'],
      );
    }

    return _groupMungkala(rows);
  }

  /// ตัดวงเล็บ/เครื่องหมายออก ให้ตรงกับที่เก็บในตาราง words
  static String _bareWord(String w) => w
      .replaceAll(RegExp('[()\\[\\]“”‘’"\'`]'), '')
      .replaceAll(RegExp(r'^[,;:.ฯ]+|[,;:.ฯ?]+$'), '')
      .trim();

  /// รวมคู่ที่เหมือนกัน แล้วเรียงตามความถี่
  ///
  /// คีย์ต้องตัดเครื่องหมายหัว-ท้ายออกก่อน ไม่งั้น "ซึ่งมงคล" · "ซึ่งมงคล," ·
  /// "ซึ่งมงคล”" จะแยกเป็นสามสำนวน ทั้งที่เครื่องหมายมาจากตำแหน่งในประโยค
  List<MungkalaGroup> _groupMungkala(List<Map<String, Object?>> rows) {
    String trim(String s) => s
        .replaceAll(RegExp('^[\\s,;:.ฯ“”‘’"\'`]+'), '')
        .replaceAll(RegExp('[\\s,;:.ฯ?“”‘’"\'`]+\$'), '');

    final order = <String>[];
    final counts = <String, int>{};
    final pali = <String, String>{};
    final thai = <String, String>{};
    final hits = <String, List<MungkalaHit>>{};

    for (final r in rows) {
      final p = trim((r['pali'] as String?) ?? '');
      final t = trim((r['thai'] as String?) ?? '');
      if (p.isEmpty || t.isEmpty) continue;
      final key = '$p\u001f$t';
      if (!counts.containsKey(key)) {
        order.add(key);
        counts[key] = 0;
        pali[key] = p;
        thai[key] = t;
        hits[key] = [];
      }
      counts[key] = counts[key]! + 1;
      if (hits[key]!.length < 12) {
        hits[key]!.add(MungkalaHit(
          page: (r['page'] as num?)?.toInt() ?? 0,
          kho: (r['kho'] as num?)?.toInt(),
          khoTitle: r['kho_title'] as String?,
        ));
      }
    }

    final out = order
        .map((k) => MungkalaGroup(
              pali: pali[k]!,
              thai: thai[k]!,
              count: counts[k]!,
              hits: hits[k]!,
            ))
        .toList();
    // สำนวนที่หนังสือใช้ซ้ำบ่อย = สำนวนหลักของคำนั้น ให้ขึ้นก่อน
    out.sort((a, b) => b.count.compareTo(a.count));
    return out.length > 60 ? out.sublist(0, 60) : out;
  }

  Future<List<DictionaryEntry>> _searchPaliToThai(
      Database db, String query) async {
    // ถอดวิภัตติ/ปัจจัย/สนธิที่พบบ่อย → candidate stems
    // เช่น ปุริโส → ปุริส, ภวตีติ → ภวติ → ภว, นาปิ → น
    final candidates = PaliStemmer.generateCandidates(query);

    // 1) exact match — ค้น original ก่อนเพื่อให้ขึ้นเป็น top result
    final exactOrig = await db.rawQuery(
      'SELECT data_json FROM entries WHERE headword = ? LIMIT 50',
      [query],
    );

    // 2) exact match บน stem candidates (ที่ไม่ใช่ original)
    final stems =
        candidates.where((c) => c != query).toList(growable: false);
    List<Map<String, Object?>> exactStems = const [];
    if (stems.isNotEmpty) {
      final placeholders = List.filled(stems.length, '?').join(',');
      exactStems = await db.rawQuery(
        'SELECT data_json FROM entries WHERE headword IN ($placeholders) LIMIT 30',
        stems,
      );
    }

    // 3) LIKE match บน original (substring)
    final excludePh = List.filled(candidates.length, '?').join(',');
    final contains = await db.rawQuery(
      'SELECT data_json FROM entries WHERE headword LIKE ? '
      'AND headword NOT IN ($excludePh) LIMIT 30',
      ['%$query%', ...candidates],
    );

    // 4) FTS5 prefix match บน headword — รวม candidates ทั้งหมดด้วย OR
    List<Map<String, Object?>> fts = const [];
    final ftsTerms = candidates
        .map(_buildFtsPrefixQuery)
        .whereType<String>()
        .map((q) => 'headword:$q')
        .join(' OR ');
    if (ftsTerms.isNotEmpty) {
      try {
        fts = await db.rawQuery('''
          SELECT e.data_json
          FROM entries_fts f
          JOIN entries e ON e.rowid = f.rowid
          WHERE entries_fts MATCH ?
          LIMIT 30
        ''', [ftsTerms]);
      } catch (_) {
        fts = const [];
      }
    }

    return _mergeUnique([
      ...exactOrig.map(_decode),
      ...exactStems.map(_decode),
      ...contains.map(_decode),
      ...fts.map(_decode),
    ]);
  }

  Future<List<DictionaryEntry>> _searchThaiToPali(
      Database db, String query) async {
    // ลบ marker ภาษาไทย (อ., ก., ซึ่ง, อัน, ใน, ของ ฯลฯ) ก่อนค้น
    final cleaned = PaliStemmer.cleanThaiQuery(query);

    final exact = await db.rawQuery(
      'SELECT data_json FROM entries WHERE gloss_th = ? OR gloss_th = ? LIMIT 50',
      [query, cleaned],
    );
    final contains = await db.rawQuery(
      '''
      SELECT data_json FROM entries
      WHERE (gloss_th LIKE ? OR gloss_th LIKE ?)
        AND gloss_th != ?
        AND gloss_th != ?
      LIMIT 60
      ''',
      ['%$query%', '%$cleaned%', query, cleaned],
    );
    return _mergeUnique([
      ...exact.map(_decode),
      ...contains.map(_decode),
    ]);
  }

  static String? _buildFtsPrefixQuery(String raw) {
    final cleaned = raw.replaceAll('"', ' ').trim();
    if (cleaned.isEmpty) return null;
    return '"$cleaned"*';
  }

  static List<DictionaryEntry> _mergeUnique(List<DictionaryEntry> entries) {
    final seen = <String>{};
    final out = <DictionaryEntry>[];
    for (final e in entries) {
      // composite key — กัน edge case ที่ id ว่างหรือซ้ำ
      final key = '${e.id}|${e.headword}|${e.homonymIndex ?? ''}|${e.glossTh}';
      if (seen.add(key)) out.add(e);
    }
    return out;
  }

  static DictionaryEntry _decode(Map<String, Object?> row) =>
      decodeEntryFromDataJson(row['data_json'] as String);

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }
}

List<int> _gunzip(List<int> input) => gzip.decode(input);
