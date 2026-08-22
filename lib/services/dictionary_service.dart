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
  /// ─── คลังข้อมูล ───────────────────────────────────────────────
  ///
  /// สามคลังแยกไฟล์กันโดยเจตนา (คนละแหล่ง คนละหน่วยข้อมูล) จึงอัปเดตทีละคลังได้
  /// ไม่ต้องขน combined 64 MB ทุกครั้งที่แก้คำแปลไม่กี่คำใน forms
  ///
  ///   combined = พจนานุกรม — มาจาก PDF วัดพระราม ๙
  ///   forms    = สะพานรูปคำผัน — สร้างจาก MySQL ฝั่งเว็บ (แก้บ่อยที่สุด)
  ///   mungkala = คลังศัพท์มังคลัตถทีปนี — คนละหนังสือ
  ///
  /// assetVersion  bump เมื่อไฟล์ที่ bundle มากับแอพเปลี่ยน → แอพแตกไฟล์ใหม่ทับของเดิม
  /// assetDate     วันที่ของข้อมูลที่ bundle มา — กันไม่ให้โหลด release ที่เก่ากว่าลงมาทับ
  /// lazy          คลังเสริมที่แตกไฟล์ต่อเมื่อผู้ใช้เปิดใช้จริง
  static const _Dataset _dsCombined = _Dataset(
    key: 'combined',
    assetPath: 'assets/data/combined.sqlite.gz',
    fileName: 'combined.sqlite',
    assetVersion: 7,
    assetDate: '2026.08.20',
    probeSql: 'SELECT count(*) FROM (SELECT 1 FROM entries LIMIT 1)',
    lazy: false,
  );

  /// 4 = ข้อมูล 22 ส.ค. 2569 — สรนฺตา "ระลึกถึงอยู่" (ไม่ใช่ …แล้ว)
  /// 3 = ซ่อมคำแปลยกศัพท์ที่ "หาไม่เจอในเฉลย" 114 ชิ้น (ส่วนใหญ่คำ อิติ ที่ตกเครื่องหมายคร่อม)
  /// 2 = ซ่อม 2 ชิ้น (เลื่อมใน→เลื่อมใส · ภควนฺตํ: ซึ่งพระศาสดา→ซึ่งพระผู้มีพระภาคเจ้า)
  static const _Dataset _dsForms = _Dataset(
    key: 'forms',
    assetPath: 'assets/data/forms.sqlite.gz',
    fileName: 'forms.sqlite',
    assetVersion: 4,
    assetDate: '2026.08.22',
    probeSql: 'SELECT count(*) FROM (SELECT 1 FROM forms LIMIT 1)',
    lazy: true,
  );

  static const _Dataset _dsMungkala = _Dataset(
    key: 'mungkala',
    assetPath: 'assets/data/mungkala.sqlite.gz',
    fileName: 'mungkala.sqlite',
    assetVersion: 1,
    assetDate: '2026.08.18',
    probeSql: 'SELECT count(*) FROM (SELECT 1 FROM pairs LIMIT 1)',
    lazy: true,
  );

  static const List<_Dataset> _datasets = [_dsCombined, _dsForms, _dsMungkala];

  /// throttle: เช็ค manifest อย่างมาก 1 ครั้งต่อช่วงเวลานี้
  static const Duration _checkInterval = Duration(hours: 6);

  static const String _kLastCheckAt = 'data_last_check_at';

  /// เวอร์ชันข้อมูลที่โหลดออนไลน์มาทับแล้ว — เก็บแยกรายคลัง
  static String _kDataVersion(_Dataset ds) => 'data_version_${ds.key}';

  Database? _db;
  Database? _formsDb;
  Database? _mkDb;

  DataUpdateStatus _updateStatus = DataUpdateStatus.idle;
  double _updateProgress = 0;
  String? _newVersion;
  bool _updateBannerDismissed = false;
  String? _updateError;
  int _lastCheckAt = 0;

  /// กันเรียกซ้อน — เช็คอัตโนมัติตอนเปิดแอพกับผู้ใช้กดปุ่ม "ตรวจอัปเดต" เอง
  /// เคยชนกันจริงตอนรันเทสต์: สองรอบโหลดไฟล์เดียวกัน แล้วแย่งกันสลับ/ลบไฟล์ชั่วคราว
  bool _checking = false;

  /// เวอร์ชันข้อมูลที่ "ใช้อยู่จริง" ของแต่ละคลัง — โชว์ในหน้าเกี่ยวกับแอพ
  final Map<String, String> _dataVersions = {
    for (final ds in _datasets) ds.key: ds.assetDate
  };

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
  String? get updateError => _updateError;
  Map<String, String> get dataVersions => Map.unmodifiable(_dataVersions);
  DateTime? get lastCheckedAt => _lastCheckAt == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(_lastCheckAt);

  /// ชื่อคลังที่อ่านออก — ใช้โชว์ในหน้าเกี่ยวกับแอพ
  static const Map<String, String> datasetLabels = {
    'combined': 'พจนานุกรมบาลี-ไทย',
    'forms': 'สะพานรูปคำผัน',
    'mungkala': 'มังคลัตถทีปนี',
  };

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

  Future<Database> _openDb() => _openBundledDb(_dsCombined);

  /// เปิดคลังหนึ่งให้พร้อมใช้ — แตกไฟล์จาก asset ถ้าจำเป็น แล้ว "ตรวจก่อนคืน"
  ///
  /// ลำดับความเชื่อถือ: ไฟล์ที่ใช้อยู่ (อาจโหลดออนไลน์มาทับ) → ของสำรอง `.bak`
  /// → ไฟล์ที่ bundle มากับแอพ (เชื่อได้เสมอ เพราะติดมาในตัวแอพ)
  /// อัปเดตออนไลน์ดับกลางคันหรือไฟล์เสีย แอพจึงยังเปิดค้นได้เหมือนเดิม
  ///
  /// แต่ละคลังมีไฟล์ `.version` ของตัวเอง — bump assetVersion ของคลังไหน ก็แตกใหม่แค่คลังนั้น
  /// ไม่ต้องแตะคลังอื่นที่ผู้ใช้มีอยู่แล้ว (ทั้งสามรวมกันแตกแล้วเกือบ 100 MB)
  Future<Database> _openBundledDb(_Dataset ds) async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/${ds.fileName}';
    final bakPath = '$dbPath.bak';

    // อัปเดตรอบก่อนดับตอนกำลังสลับไฟล์ → เอาของสำรองกลับมาก่อน
    if (!await File(dbPath).exists() && await File(bakPath).exists()) {
      await File(bakPath).rename(dbPath);
      debugPrint('${ds.fileName}: กู้จากไฟล์สำรอง .bak');
    }

    var needCopy = !await File(dbPath).exists();
    if (!needCopy) {
      final f = File('$dbPath.version');
      final txt = await f.exists() ? (await f.readAsString()).trim() : '';
      // ไฟล์ใน bundle เป็นชุดใหม่ (หรือไม่รู้ที่มา) → แตกทับ
      needCopy = int.tryParse(txt) != ds.assetVersion;
    }
    if (needCopy) await _restoreFromAsset(ds, dbPath);

    try {
      return await _openVerified(dbPath, ds.probeSql);
    } catch (e) {
      // เปิดไม่ได้/ข้อมูลหาย — ถอยไปใช้ของที่ bundle มา แล้วลองใหม่ครั้งเดียว
      debugPrint('${ds.fileName} ใช้ไม่ได้ ($e) → แตกใหม่จาก bundle');
      await _restoreFromAsset(ds, dbPath);
      return _openVerified(dbPath, ds.probeSql);
    }
  }

  /// แตกไฟล์ .sqlite.gz จาก asset ทับของเดิม แล้วลืมเวอร์ชันออนไลน์ทิ้ง
  /// (ของใน bundle มาจาก build ใหม่กว่าเสมอ ตามวันที่ใน assetDate)
  Future<void> _restoreFromAsset(_Dataset ds, String dbPath) async {
    // ship gzipped (รวมสามคลัง ~15 MB เทียบ 96 MB ถ้าไม่บีบ) — แตกครั้งแรกที่เปิดแอพ
    final data = await rootBundle.load(ds.assetPath);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final decoded = await compute(_gunzip, bytes);
    await File(dbPath).writeAsBytes(decoded, flush: true);
    await File('$dbPath.version').writeAsString('${ds.assetVersion}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDataVersion(ds));
    _dataVersions[ds.key] = ds.assetDate;
  }

  /// เปิดแบบอ่านอย่างเดียว + ตรวจว่าไฟล์ใช้การได้จริง
  ///
  /// [deep] = true ใช้กับไฟล์ที่เพิ่งโหลดมาเท่านั้น — `quick_check` อ่านทั้งไฟล์
  /// ถ้าทำทุกครั้งที่เปิดแอพจะหน่วงหลายวินาทีเพราะพจนานุกรมใหญ่ 64 MB
  /// ส่วน probeSql เป็นคำถามที่ตอบได้ทันที (LIMIT 1) จึงตรวจได้ทุกครั้ง
  ///
  /// โยน exception ถ้าไม่ผ่าน — ผู้เรียกเป็นคนตัดสินใจว่าจะกู้อย่างไร
  Future<Database> _openVerified(String path, String probeSql,
      {bool deep = false}) async {
    final db = await openDatabase(path, readOnly: true);
    try {
      if (deep) {
        final r = await db.rawQuery('PRAGMA quick_check(1)');
        final verdict =
            r.isEmpty ? '' : '${r.first.values.first}'.toLowerCase();
        if (verdict != 'ok') throw Exception('ไฟล์เสีย (quick_check: $verdict)');
      }
      final rows = Sqflite.firstIntValue(await db.rawQuery(probeSql)) ?? 0;
      if (rows <= 0) throw Exception('ไม่มีข้อมูล ($probeSql)');
      return db;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  /// เปิดคลังเสริมแบบ lazy — ผู้ใช้ที่ไม่เคยค้นคำผันหรือไม่เคยเปิดเล่มมังคลัตถทีปนี
  /// จะไม่เสียเวลาแตกไฟล์ 15–17 MB ตอนเปิดแอพ
  /// ล้มเหลวก็คืน null ให้ฟีเจอร์นั้นเงียบไป ไม่ทำให้พจนานุกรมหลักพัง
  Future<Database?> _ensureFormsDb() async {
    if (_formsDb != null) return _formsDb;
    try {
      _formsDb = await _openBundledDb(_dsForms);
    } catch (e) {
      debugPrint('_ensureFormsDb error: $e');
      return null;
    }
    return _formsDb;
  }

  Future<Database?> _ensureMungkalaDb() async {
    if (_mkDb != null) return _mkDb;
    try {
      _mkDb = await _openBundledDb(_dsMungkala);
    } catch (e) {
      debugPrint('_ensureMungkalaDb error: $e');
      return null;
    }
    return _mkDb;
  }

  // ─── online dataset updates ──────────────────────────────────

  /// เช็ค manifest บน GitHub Releases แล้วอัปเดตคลังที่มีของใหม่กว่า
  ///
  /// ทำทีละคลัง คลังไหนพลาดก็ไม่ลามไปคลังอื่น และไม่มีคลังไหนถูกทิ้งไว้ครึ่ง ๆ กลาง ๆ
  /// (ดูเงื่อนไขการกู้คืนใน [_applyUpdate])
  Future<void> checkForUpdates({bool force = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _loadDataVersions(prefs);

      if (!force) {
        final last = prefs.getInt(_kLastCheckAt) ?? 0;
        final since = DateTime.now().millisecondsSinceEpoch - last;
        if (since < _checkInterval.inMilliseconds) return;
      }

      _updateStatus = DataUpdateStatus.checking;
      _updateError = null;
      notifyListeners();

      final manifests = await UpdateService.fetchManifest();
      _lastCheckAt = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kLastCheckAt, _lastCheckAt);

      if (manifests == null || manifests.isEmpty) {
        _updateStatus = DataUpdateStatus.idle;
        notifyListeners();
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      var applied = 0;
      for (final ds in _datasets) {
        final m = manifests[ds.key];
        if (m == null) continue;

        // คลังเสริมที่ผู้ใช้ยังไม่เคยเปิด ยังไม่ต้องโหลด — ไว้แตกจาก bundle ตอนใช้จริงก่อน
        // แล้วรอบหน้าค่อยอัปเดต (ประหยัดเน็ตคนที่ไม่ได้เปิดเล่มมังคลัตถทีปนี)
        if (ds.lazy && !await File('${dir.path}/${ds.fileName}').exists()) {
          continue;
        }

        // ไม่ถอยหลัง: โหลดเฉพาะเมื่อของบนเซิร์ฟเวอร์ใหม่กว่าที่ใช้อยู่จริง
        // (เทียบสตริงวันที่ YYYY.MM.DD ตรง ๆ ได้ เพราะเรียงตามตัวอักษร = เรียงตามเวลา)
        final current = _dataVersions[ds.key] ?? ds.assetDate;
        if (m.version.compareTo(current) <= 0) continue;

        if (await _applyUpdate(ds, m, prefs)) applied++;
      }

      if (applied > 0) {
        _updateStatus = DataUpdateStatus.applied;
        _updateProgress = 1;
      } else {
        _updateStatus = _updateError == null
            ? DataUpdateStatus.idle
            : DataUpdateStatus.error;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('checkForUpdates error: $e');
      _updateError = '$e';
      _updateStatus = DataUpdateStatus.error;
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  void _loadDataVersions(SharedPreferences prefs) {
    for (final ds in _datasets) {
      _dataVersions[ds.key] = prefs.getString(_kDataVersion(ds)) ?? ds.assetDate;
    }
  }

  /// โหลดข้อมูลคลังหนึ่งมาทับแบบ "ล้มแล้วกลับที่เดิมได้"
  ///
  /// ลำดับ: โหลด → เทียบ sha256 → คลายไฟล์ → **ตรวจว่าเปิดได้จริงก่อนสลับ**
  /// → ปิดของเดิมแล้ว rename เป็น `.bak` (ไม่กินที่เพิ่ม) → สลับของใหม่เข้ามา
  /// → เปิดของใหม่ตรวจอีกรอบ → ค่อยลบ `.bak`
  ///
  /// พังตรงไหนก็ตาม ของเดิมถูกคืนกลับมาและเปิดใช้ต่อได้ทันที
  /// ถ้าคืนไม่สำเร็จจริง ๆ ยังมีทางสุดท้ายคือแตกใหม่จากไฟล์ที่ bundle มากับแอพ
  Future<bool> _applyUpdate(
      _Dataset ds, DataManifest m, SharedPreferences prefs) async {
    _updateStatus = DataUpdateStatus.downloading;
    _updateProgress = 0;
    _newVersion = m.version;
    _updateBannerDismissed = false;
    notifyListeners();

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/${ds.fileName}';
    final gzPath = '$dbPath.gz.new';
    final newPath = '$dbPath.new';
    final bakPath = '$dbPath.bak';

    var swapped = false;
    try {
      final ok = await UpdateService.downloadGz(
        url: m.url,
        destPath: gzPath,
        onProgress: (p) {
          if (p >= 0) {
            _updateProgress = p;
            notifyListeners();
          }
        },
      );
      if (!ok) throw Exception('ดาวน์โหลดไม่สำเร็จ');

      final actualSha = await UpdateService.sha256OfFile(gzPath);
      if (actualSha != m.sha256) {
        throw Exception('sha256 ไม่ตรง: $actualSha ≠ ${m.sha256}');
      }

      final gzBytes = await File(gzPath).readAsBytes();
      final decoded = await compute(_gunzip, gzBytes);
      await File(newPath).writeAsBytes(decoded, flush: true);

      // ตรวจให้ผ่านก่อน ยังไม่แตะของเดิม
      final probe = await _openVerified(newPath, ds.probeSql, deep: true);
      await probe.close();

      await _dbOf(ds)?.close();
      _setDb(ds, null);
      if (await File(dbPath).exists()) await File(dbPath).rename(bakPath);
      await File(newPath).rename(dbPath);
      swapped = true;

      _setDb(ds, await _openVerified(dbPath, ds.probeSql));
      await File('$dbPath.version').writeAsString('${ds.assetVersion}');
      await prefs.setString(_kDataVersion(ds), m.version);
      _dataVersions[ds.key] = m.version;

      await _deleteQuietly(bakPath);
      await _deleteQuietly(gzPath);
      debugPrint('อัปเดต ${ds.key} → ${m.version} สำเร็จ');
      return true;
    } catch (e) {
      debugPrint('_applyUpdate(${ds.key}) error: $e');
      _updateError = '${datasetLabels[ds.key] ?? ds.key}: $e';
      await _rollback(ds, dbPath, bakPath, swapped);
      await _deleteQuietly(gzPath);
      await _deleteQuietly(newPath);
      return false;
    }
  }

  /// คืนข้อมูลชุดเดิมหลังอัปเดตล้มเหลว
  Future<void> _rollback(
      _Dataset ds, String dbPath, String bakPath, bool swapped) async {
    try {
      if (swapped && await File(bakPath).exists()) {
        await _deleteQuietly(dbPath);
        await File(bakPath).rename(dbPath);
        debugPrint('${ds.key}: คืนข้อมูลชุดเดิมแล้ว');
      }
      if (_dbOf(ds) == null && await File(dbPath).exists()) {
        _setDb(ds, await _openVerified(dbPath, ds.probeSql));
      }
    } catch (e) {
      debugPrint('${ds.key}: คืนของเดิมไม่สำเร็จ ($e) → ใช้ชุดที่ bundle มา');
      try {
        _setDb(ds, await _openBundledDb(ds));
      } catch (e2) {
        debugPrint('${ds.key}: เปิดชุดที่ bundle มาก็ไม่ได้: $e2');
      }
    }
  }

  Database? _dbOf(_Dataset ds) {
    if (ds.key == _dsCombined.key) return _db;
    if (ds.key == _dsForms.key) return _formsDb;
    return _mkDb;
  }

  void _setDb(_Dataset ds, Database? db) {
    if (ds.key == _dsCombined.key) {
      _db = db;
    } else if (ds.key == _dsForms.key) {
      _formsDb = db;
    } else {
      _mkDb = db;
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
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

/// คลังข้อมูลหนึ่งชุดที่ bundle มากับแอพ และอัปเดตออนไลน์ทีหลังได้
class _Dataset {
  const _Dataset({
    required this.key,
    required this.assetPath,
    required this.fileName,
    required this.assetVersion,
    required this.assetDate,
    required this.probeSql,
    required this.lazy,
  });

  /// ชื่อคลังใน manifest.json — ต้องตรงกับฝั่ง scripts/release-data.sh
  final String key;
  final String assetPath;
  final String fileName;
  final int assetVersion;
  final String assetDate;
  final String probeSql;
  final bool lazy;
}
