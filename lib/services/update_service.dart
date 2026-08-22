import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GitHub repo ที่ host data releases — แก้ตรงนี้ครั้งเดียว
const String _githubOwner = 'purivaro';
const String _githubRepo = 'puridict';

/// ชี้ manifest ไปที่อื่นตอนทดสอบ — `--dart-define=DATA_MANIFEST_URL=http://127.0.0.1:…`
/// ใช้ในเทสต์ integration_test/data_update_test.dart เท่านั้น ปกติเป็นค่าว่าง
const String _manifestUrlOverride =
    String.fromEnvironment('DATA_MANIFEST_URL');

/// `releases/latest/download/<file>` redirect ไป release ล่าสุดอัตโนมัติ
String get manifestUrl => _manifestUrlOverride.isNotEmpty
    ? _manifestUrlOverride
    : 'https://github.com/$_githubOwner/$_githubRepo/releases/latest/download/manifest.json';

/// ข้อมูลหนึ่งคลังใน manifest.json
///
/// manifest ที่ใช้อยู่มีสองรูปแบบ และแอพอ่านได้ทั้งคู่:
///
/// ```jsonc
/// // รูปแบบใหม่ — หลายคลังในไฟล์เดียว (ต้องมีครบทุกคลังเสมอ ไม่ใช่เฉพาะที่เพิ่งแก้
/// // เพราะ releases/latest ชี้ไปที่ release ล่าสุดอันเดียว)
/// {
///   "datasets": {
///     "combined": { "version": "2026.08.20", "size": …, "sha256": "…", "url": "…" },
///     "forms":    { "version": "2026.08.22", … },
///     "mungkala": { "version": "2026.08.18", … }
///   }
/// }
///
/// // รูปแบบเดิม (แอพรุ่น ≤ 2.1.0) — คลังเดียว ไม่มีชื่อ = combined
/// { "version": "…", "size": …, "sha256": "…", "url": "…" }
/// ```
class DataManifest {
  final String name;
  final String version;
  final int size;
  final String sha256;
  final String url;

  DataManifest({
    required this.name,
    required this.version,
    required this.size,
    required this.sha256,
    required this.url,
  });

  /// คืน null ถ้าฟิลด์ไม่ครบ/ผิดชนิด — คลังที่เสียถูกข้ามไป ไม่ทำให้ทั้ง manifest ใช้ไม่ได้
  static DataManifest? tryParse(String name, Map<String, dynamic> j) {
    final version = j['version'];
    final size = j['size'];
    final sha = j['sha256'];
    final url = j['url'];
    if (version is! String || size is! num || sha is! String || url is! String) {
      return null;
    }
    if (version.isEmpty || sha.isEmpty || url.isEmpty) return null;
    return DataManifest(
      name: name,
      version: version,
      size: size.toInt(),
      sha256: sha.toLowerCase(),
      url: url,
    );
  }

  /// แกะ manifest ทั้งไฟล์เป็น map ชื่อคลัง → รายละเอียด
  static Map<String, DataManifest> parseAll(Map<String, dynamic> j) {
    final out = <String, DataManifest>{};

    final ds = j['datasets'];
    if (ds is Map) {
      ds.forEach((k, v) {
        if (k is String && v is Map) {
          final m = tryParse(k, Map<String, dynamic>.from(v));
          if (m != null) out[k] = m;
        }
      });
    }

    // ไม่มี datasets → manifest รูปแบบเดิม ถือว่าเป็นคลังพจนานุกรม
    if (out.isEmpty) {
      final m = tryParse('combined', j);
      if (m != null) out['combined'] = m;
    }
    return out;
  }
}

class UpdateService {
  /// fetch manifest.json จาก GitHub Releases
  /// คืน null ถ้าไม่มีเน็ต / ยังไม่เคย publish release / parse fail
  static Future<Map<String, DataManifest>?> fetchManifest({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final resp = await http.get(Uri.parse(manifestUrl)).timeout(timeout);
      if (resp.statusCode != 200) {
        debugPrint('fetchManifest: HTTP ${resp.statusCode}');
        return null;
      }
      final decoded = json.decode(utf8.decode(resp.bodyBytes));
      if (decoded is! Map) return null;
      final all = DataManifest.parseAll(Map<String, dynamic>.from(decoded));
      return all.isEmpty ? null : all;
    } catch (e) {
      debugPrint('UpdateService.fetchManifest error: $e');
      return null;
    }
  }

  /// download ไฟล์ .sqlite.gz มาที่ [destPath]
  /// onProgress: 0..1 (ถ้ามี Content-Length); -1 ถ้าไม่ทราบขนาด
  static Future<bool> downloadGz({
    required String url,
    required String destPath,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final req = http.Request('GET', Uri.parse(url));
      final streamed = await http.Client().send(req);
      if (streamed.statusCode != 200) {
        debugPrint('downloadGz: HTTP ${streamed.statusCode}');
        return false;
      }
      final total = streamed.contentLength ?? -1;
      final sink = File(destPath).openWrite();
      int received = 0;
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null) {
          onProgress(total > 0 ? received / total : -1);
        }
      }
      await sink.close();
      return true;
    } catch (e) {
      debugPrint('UpdateService.downloadGz error: $e');
      return false;
    }
  }

  /// คำนวน sha256 ของไฟล์แบบ stream (ไม่โหลดทั้งไฟล์เข้า memory)
  static Future<String> sha256OfFile(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString().toLowerCase();
  }
}
