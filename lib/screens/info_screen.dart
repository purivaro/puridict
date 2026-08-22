import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:puridict/services/dictionary_service.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกี่ยวกับ PuriDict', style: TextStyle(
          color: Colors.white
        )),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'PuriDict เป็นพจนานุกรมบาลี-ไทย ออนไลน์ที่ช่วยให้ผู้ใช้สามารถค้นหาคำศัพท์บาลีและความหมายในภาษาไทยได้อย่างง่ายดาย',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'คุณสมบัติ:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(context, 'ค้นหาได้ทั้งบาลี-ไทย และไทย-บาลี'),
              _buildFeatureItem(context, 'บันทึกรายการโปรดได้'),
              _buildFeatureItem(context, 'เก็บประวัติการค้นหา'),
              _buildFeatureItem(context, 'ปรับขนาดตัวอักษรได้'),
              _buildFeatureItem(context, 'มีโหมดกลางคืน'),
              _buildFeatureItem(context, 'ไม่ต้องใช้อินเทอร์เน็ต (Offline)'),
              const SizedBox(height: 24),
              const _DataUpdateSection(),
              const SizedBox(height: 24),
              Text(
                'ขอบคุณข้อมูลจาก พจนานุกรมบาลี - ไทย อรรถกถาธรรมบท ภาค ๑ - ๘ วัดพระราม ๙ กาญจนาภิเษก กรุงเทพฯ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.book,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PuriDict v.2.2.0',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 พัฒนาโดย พระมหาอนวัช ภูริวโร',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// ส่วน "ข้อมูลในเครื่อง" — บอกว่าแต่ละคลังใช้ข้อมูลชุดวันไหนอยู่
/// และกดตรวจอัปเดตเองได้ ไม่ต้องรอรอบ 6 ชั่วโมง
class _DataUpdateSection extends StatelessWidget {
  const _DataUpdateSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DictionaryService>(context);
    final theme = Theme.of(context);
    final busy = service.updateStatus == DataUpdateStatus.checking ||
        service.updateStatus == DataUpdateStatus.downloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ข้อมูลในเครื่อง:',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...service.dataVersions.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DictionaryService.datasetLabels[e.key] ?? e.key,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _thaiDate(e.value),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(_statusText(service), style: theme.textTheme.bodySmall)),
            TextButton.icon(
              onPressed:
                  busy ? null : () => service.checkForUpdates(force: true),
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('ตรวจอัปเดต'),
            ),
          ],
        ),
      ],
    );
  }

  String _statusText(DictionaryService s) {
    switch (s.updateStatus) {
      case DataUpdateStatus.checking:
        return 'กำลังตรวจข้อมูลใหม่...';
      case DataUpdateStatus.downloading:
        return 'กำลังดาวน์โหลดข้อมูลใหม่...';
      case DataUpdateStatus.applied:
        return 'อัพเดทข้อมูลเรียบร้อยแล้ว';
      case DataUpdateStatus.error:
        // ล้มเหลวแล้วยังใช้งานต่อได้ เพราะระบบคืนข้อมูลชุดเดิมให้อัตโนมัติ
        return 'อัพเดทไม่สำเร็จ — ยังใช้ข้อมูลชุดเดิมได้ตามปกติ';
      case DataUpdateStatus.idle:
        final at = s.lastCheckedAt;
        if (at == null) return 'ยังไม่เคยตรวจอัปเดต';
        return 'ตรวจล่าสุด ${_clock(at)} — ข้อมูลเป็นชุดล่าสุดแล้ว';
    }
  }

  /// '2026.08.22' → '22 ส.ค. 2569'
  String _thaiDate(String v) {
    final p = v.split('.');
    if (p.length != 3) return v;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) return v;
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '$d ${months[m - 1]} ${y + 543}';
  }

  String _clock(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.day}/${t.month} $hh:$mm';
  }
}
