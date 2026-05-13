import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:puridict/models/dictionary_entry.dart';
import 'package:puridict/services/pali_stemmer.dart';
import 'package:puridict/services/update_service.dart';

enum DataUpdateStatus { idle, checking, downloading, applied, error }

class DictionaryService extends ChangeNotifier {
  static const String _assetDbPath = 'assets/data/combined.sqlite.gz';
  static const String _dbFileName = 'combined.sqlite';

  /// bump เมื่ออัปเดตไฟล์ dataset ที่ bundle มา (จะ trigger copy ใหม่)
  static const int _assetDbVersion = 5;

  /// throttle: เช็ค manifest อย่างมาก 1 ครั้งต่อช่วงเวลานี้
  static const Duration _checkInterval = Duration(hours: 6);

  static const String _kRemoteVersion = 'data_remote_version';
  static const String _kLastCheckAt = 'data_last_check_at';

  Database? _db;

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

  Future<void> loadDictionary() async {
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

  Future<Database> _openDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/$_dbFileName';
    final versionFile = File('${dir.path}/$_dbFileName.version');

    bool needCopy = !await File(dbPath).exists();
    if (!needCopy && await versionFile.exists()) {
      final v = int.tryParse((await versionFile.readAsString()).trim()) ?? 0;
      if (v != _assetDbVersion) needCopy = true;
    } else if (!needCopy) {
      needCopy = true;
    }

    if (needCopy) {
      // ship gzipped (~6.7 MB vs 64 MB raw) — decompress on first run
      final data = await rootBundle.load(_assetDbPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final decoded = await compute(_gunzip, bytes);
      await File(dbPath).writeAsBytes(decoded, flush: true);
      await versionFile.writeAsString('$_assetDbVersion');
    }

    return openDatabase(dbPath, readOnly: true);
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
    notifyListeners();
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

    try {
      _filteredEntries = _dictionaryType == 'paliThai'
          ? await _searchPaliToThai(db, query)
          : await _searchThaiToPali(db, query);
    } catch (e) {
      _error = 'ค้นหาไม่สำเร็จ: $e';
      _filteredEntries = [];
    }

    _searchPerformed = true;
    _loading = false;
    _showRecentSearches = false;
    notifyListeners();
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
