import 'package:flutter/material.dart';

import 'package:puridict/models/inflected_info.dart';
import 'package:puridict/theme/app_theme.dart';

/// กล่องอธิบายว่าคำที่ค้นเป็นรูปที่ผันแล้วของศัพท์แม่ตัวไหน
///
/// ขึ้นเหนือรายการผล เพราะเป็นข้อสรุปที่ช่วยให้ผู้อ่านเข้าใจว่าทำไมพจนานุกรม
/// แสดงคำอื่น (ค้น "ราชา" แล้วได้รายการของ "ราช")
/// "หนังสือแปลว่า" คือคำแปลที่ยกจากธรรมบทแปลโดยพยัญชนะจริง ไม่ใช่คำแปลพจนานุกรม
class InflectedBanner extends StatelessWidget {
  final InflectedInfo info;

  const InflectedBanner({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final readings = info.distinctReadings;
    final muted = isDark ? AppTheme.darkTextLightColor : AppTheme.lightTextLightColor;
    final accent = isDark ? AppTheme.primaryLightColor : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, size: 18, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: info.surface,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    TextSpan(
                      text: '  เป็นรูปที่ผันแล้ว',
                      style: TextStyle(fontSize: 13, color: accent),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (readings.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(
              context,
              'ศัพท์แม่',
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: readings
                    .map((r) => Text.rich(TextSpan(children: [
                          TextSpan(
                            text: r.lemma,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          if (r.tags.isNotEmpty)
                            TextSpan(
                              text: '  ${r.tags.join(' · ')}',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                        ])))
                    .toList(growable: false),
              ),
            ),
          ],
          if (info.parts.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(
              context,
              'แยกสนธิ',
              Text(info.parts.join(' + '), style: const TextStyle(fontSize: 18)),
            ),
          ],
          if (info.glosses.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(
              context,
              'หนังสือแปลว่า',
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: info.glosses
                    .take(5)
                    .map((g) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: g.gloss),
                            TextSpan(
                              text: '  ${g.count}',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ])),
                        ))
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'คำแปลข้างบนยกจากธรรมบทแปลโดยพยัญชนะทั้ง ๘ ภาค · เลขคือจำนวนที่พบ',
            style: TextStyle(fontSize: 10.5, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, Widget body) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextLightColor
        : AppTheme.lightTextLightColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(label,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, color: muted)),
          ),
          const SizedBox(width: 10),
          Expanded(child: body),
        ],
      ),
    );
  }
}
