import 'package:flutter/material.dart';

import 'package:puridict/models/mungkala_group.dart';
import 'package:puridict/theme/app_theme.dart';

/// การ์ดผลค้นหาของเล่มมังคลัตถทีปนี
///
/// ต่างจากการ์ดพจนานุกรม (DictionaryCard) เพราะหน่วยข้อมูลต่างกัน:
///   พจนานุกรม = headword ๑ คำ + ความหมาย/ชนิดคำ/วิคหะ
///   ที่นี่     = ก้อนบาลีอย่างที่หนังสือยกไว้ + คำแปลของก้อนนั้น + ที่พบ (หน้า/ข้อ)
/// จึงเป็นวิดเจ็ตแยก ไม่ยัดเข้าการ์ดเดิม
class MungkalaCard extends StatelessWidget {
  final MungkalaGroup group;
  final double fontSize;

  const MungkalaCard({super.key, required this.group, this.fontSize = 1.2});

  /// สีคำที่หนังสือเสริม/โยคเข้ามา — เขียวชุดเดียวกับแถวบาลีโยคศัพท์บนเว็บ (#15803d)
  static const Color _supplied = Color(0xFF15803D);
  static const Color _suppliedDark = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkTextLightColor : AppTheme.lightTextLightColor;
    final supplied = isDark ? _suppliedDark : _supplied;
    final hit = group.firstHit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: group.paliPieces
                  .map((p) => TextSpan(
                        text: p.text,
                        style: TextStyle(color: p.supplied ? supplied : null),
                      ))
                  .toList(growable: false),
            ),
            style: TextStyle(
              fontSize: 18 * fontSize / 1.2,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            group.thai,
            style: TextStyle(fontSize: 14.5, height: 1.6, color: muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(Icons.repeat, 'พบ ${group.count} ที่', muted),
              if (group.pages.isNotEmpty)
                _chip(Icons.menu_book_outlined,
                    'หน้า ${group.pages.join(', ')}', muted),
              if (hit?.kho != null) _chip(null, 'ข้อ ${hit!.kho}', muted),
            ],
          ),
          if (hit?.khoTitle != null && hit!.khoTitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(hit.khoTitle!, style: TextStyle(fontSize: 11.5, color: muted)),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData? icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(fontSize: 11.5, color: color)),
        ],
      );
}
