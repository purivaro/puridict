import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GitHub repo ที่ host data releases — แก้ตรงนี้ครั้งเดียว
const String _githubOwner = 'purivaro';
const String _githubRepo = 'puridict';

/// `releases/latest/download/<file>` redirect ไป release ล่าสุดอัตโนมัติ
String get manifestUrl =>
    'https://github.com/$_githubOwner/$_githubRepo/releases/latest/download/manifest.json';

class DataManifest {
  final String version;
  final int size;
  final String sha256;
  final String url;

  DataManifest({
    required this.version,
    required this.size,
    required this.sha256,
    required this.url,
  });

  factory DataManifest.fromJson(Map<String, dynamic> j) => DataManifest(
        version: j['version'] as String,
        size: (j['size'] as num).toInt(),
        sha256: (j['sha256'] as String).toLowerCase(),
        url: j['url'] as String,
      );
}

class UpdateService {
  /// fetch manifest.json จาก GitHub Releases
  /// คืน null ถ้าไม่มีเน็ต / repo ยังไม่ตั้ง / parse fail
  static Future<DataManifest?> fetchManifest({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_githubOwner == 'YOUR_GITHUB_USER') return null;
    try {
      final resp = await http.get(Uri.parse(manifestUrl)).timeout(timeout);
      if (resp.statusCode != 200) return null;
      return DataManifest.fromJson(
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
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
