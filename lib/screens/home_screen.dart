import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puridict/screens/info_screen.dart';
import 'package:puridict/services/dictionary_service.dart';
import 'package:puridict/theme/app_theme.dart';
import 'package:puridict/theme/theme_manager.dart';
import 'package:puridict/widgets/dictionary_card.dart';
import 'package:puridict/widgets/favorites_section.dart';
import 'package:puridict/widgets/loading_skeleton.dart';
import 'package:puridict/widgets/search_box.dart';
import 'package:puridict/widgets/inflected_banner.dart';
import 'package:puridict/widgets/mungkala_card.dart';
import 'package:puridict/widgets/recent_searches.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dictionaryService = Provider.of<DictionaryService>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkBgColor 
                  : AppTheme.lightBgColor,
      body: Column(
        children: [
          // Header ที่มีสีน้ำเงิน (รวมถึง status bar)
          _buildHeader(context, dictionaryService, themeManager),
          
          // เนื้อหาด้านล่างที่มีพื้นหลังสีอ่อน
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkBgColor 
                  : AppTheme.lightBgColor,
              child: Column(
                children: [
                  // Dictionary Type Selector
                  _buildDictionaryTypeSelector(context, dictionaryService),

                  // Update banner (โผล่เฉพาะตอนกำลัง download / เพิ่งอัพเดทเสร็จ)
                  _UpdateBanner(service: dictionaryService),

                  // Search Box
                  SearchBox(),
                  
                  // Recent Searches Dropdown
                  if (dictionaryService.showRecentSearches)
                    RecentSearches(),
                  
                  // เนื้อหาหลัก
                  Expanded(
                    child: dictionaryService.loading
                      ? LoadingSkeleton()
                      : dictionaryService.error != null
                        ? _buildErrorMessage(context, dictionaryService)
                        : dictionaryService.searchPerformed
                          ? _buildResultsSection(context, dictionaryService)
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: FavoritesSection(),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DictionaryService service, ThemeManager themeManager) {
    // คำนวณความสูงของ status bar
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Luxury sapphire–indigo gradient (4 stops) ใส feel ลึก
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.4),
          end: const Alignment(1.0, 1.0),
          colors: isDark
              ? const [
                  Color(0xFF132A6E),
                  Color(0xFF1E3A8A),
                  Color(0xFF2851B8),
                ]
              : const [
                  Color(0xFF1E3A8A), // royal blue (เริ่มสว่างกว่าเดิม)
                  Color(0xFF2851B8), // luminous royal
                  Color(0xFF3B6FE0), // vibrant royal
                  Color(0xFF5B8DEF), // bright sky royal (จบสว่างสดใส)
                ],
          stops: isDark
              ? const [0.0, 0.55, 1.0]
              : const [0.0, 0.40, 0.75, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(isDark ? 0.0 : 0.35),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        // glossy highlight ด้านบน — เพิ่มความ premium แบบ metallic
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, -0.2),
          colors: [
            Colors.white.withOpacity(isDark ? 0.04 : 0.10),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: statusBarHeight + 2,
        bottom: 10,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Puri Dictionary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                context,
                icon: Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                onTap: () => themeManager.toggleTheme(),
              ),
              _buildHeaderButton(
                context,
                icon: Icons.info_outline,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoScreen()),
                ),
              ),
              _buildHeaderButton(
                context,
                icon: Icons.history,
                onTap: () => service.toggleRecentSearches(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      width: 32,
      height: 32,
      child: Center(
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 16),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildDictionaryTypeSelector(BuildContext context, DictionaryService service) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // เรียงแบบเดียวกับเว็บ: [ธรรมบท] [บาลี-ไทย] [ไทย-บาลี] [มังคลัตถทีปนี]
      // ปุ่มเล่มขนาบสองข้าง สวิตช์ทิศทางอยู่กลางเพราะใช้ร่วมกันทั้งสองเล่ม
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              title: 'ธรรมบท',
              icon: Icons.menu_book,
              isSelected: service.book == 'dhammapada',
              onTap: () => service.changeBook('dhammapada'),
              activeColors: _bookColors,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              context,
              title: 'บาลี-ไทย',
              icon: Icons.language,
              isSelected: service.dictionaryType == 'paliThai',
              onTap: () => service.changeDictionaryType('paliThai'),
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              context,
              title: 'ไทย-บาลี',
              icon: Icons.swap_horiz,
              isSelected: service.dictionaryType == 'thaiPali',
              onTap: () => service.changeDictionaryType('thaiPali'),
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              context,
              title: 'มังคลัตถ',
              icon: Icons.auto_stories,
              isSelected: service.book == 'mungkala',
              onTap: () => service.changeBook('mungkala'),
              activeColors: _bookColors,
            ),
          ),
        ],
      ),
    );
  }

  /// สีปุ่มเลือกเล่ม — โทนเดียวกับฝั่งเว็บ (--pd-book #047857) ให้สองแพลตฟอร์มอ่านเหมือนกัน
  static const List<Color> _bookColors = [Color(0xFF065F46), Color(0xFF047857)];

  Widget _buildTypeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    // ปุ่มเลือกเล่มใช้เขียว ปุ่มเลือกทิศทางใช้น้ำเงินเดิม — แถบเดียวมีสองเรื่องอยู่ในนั้น
    // และปุ่มสว่างพร้อมกันได้สองปุ่ม ถ้าสีเดียวกันหมดจะดูเหมือนเลือกซ้อนกันผิด
    List<Color>? activeColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: const Alignment(-1.0, -0.4),
                  end: const Alignment(1.0, 1.0),
                  colors: activeColors ??
                      (isDark
                          ? const [
                              Color(0xFF1E3A8A),
                              Color(0xFF2851B8),
                            ]
                          : const [
                              Color(0xFF1E3A8A),
                              Color(0xFF2851B8),
                              Color(0xFF3B6FE0),
                            ]),
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (activeColors?.first ?? const Color(0xFF1E3A8A))
                        .withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        foregroundDecoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.2),
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).brightness == Brightness.dark ? (
                isSelected ? Colors.white : AppTheme.darkTextLightColor
              ) : (
                isSelected ? Colors.white : Theme.of(context).primaryColor
              )
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? (
                  isSelected ? Colors.white : AppTheme.darkTextLightColor
                ) : (
                  isSelected ? Colors.white : Theme.of(context).primaryColor
                ),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, DictionaryService service) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(service.error!),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => service.loadDictionary(),
            child: Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, DictionaryService service) {
    // เล่มมังคลัตถทีปนีมีรูปผลลัพธ์ของตัวเอง (คู่บาลี-คำแปล) ไม่ใช่ entries
    if (service.book == 'mungkala') {
      return _buildMungkalaSection(context, service);
    }
    if (service.filteredEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16), // ปรับค่านี้ให้เหมือนกับใน search_box
        child: Container(
          margin: const EdgeInsets.only(bottom: 16), // เหลือเฉพาะ margin ด้านล่าง
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 16),
              Text(
                'ไม่พบคำที่ค้นหา "${service.searchQuery}"',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'คำแนะนำ:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• ตรวจสอบการสะกดคำให้ถูกต้อง\n• ลองค้นหาด้วยคำที่สั้นลง หรือตัดวิภัตติออกก่อน',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Stats
        Padding(
          // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 2,
            bottom: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'พบ ${service.filteredEntries.length} รายการ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => service.changeFontSize(-0.1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Icon(
                        Icons.text_decrease,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => service.changeFontSize(0.1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Icon(
                        Icons.text_increase,
                        size: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // วิธีการแสดงผลที่ใช้งานได้ใน TestFlight
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // สะพานรูปคำผัน — ขึ้นเหนือผล เพราะเป็นข้อสรุปว่าทำไมได้คำอื่น
                if (service.inflected != null)
                  InflectedBanner(info: service.inflected!),
                ...service.filteredEntries.map((entry) => DictionaryCard(
                      entry: entry,
                      isTopResult:
                          service.filteredEntries.indexOf(entry) == 0,
                      fontSize: service.fontSize,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// หน้าผลของเล่มมังคลัตถทีปนี — คู่บาลี-คำแปล + ที่พบในหนังสือ
  Widget _buildMungkalaSection(BuildContext context, DictionaryService service) {
    final groups = service.mungkalaGroups;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextLightColor
        : AppTheme.lightTextLightColor;

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 40, color: muted),
              const SizedBox(height: 10),
              Text('ไม่พบ "${service.searchQuery}" ในมังคลัตถทีปนี',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            'พบ ${groups.length} สำนวน จากมังคลัตถทีปนี',
            style: TextStyle(fontSize: 12.5, color: muted),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: groups
                  .map((g) => MungkalaCard(group: g, fontSize: service.fontSize))
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final DictionaryService service;
  const _UpdateBanner({required this.service});

  @override
  Widget build(BuildContext context) {
    final s = service.updateStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (s == DataUpdateStatus.idle ||
        s == DataUpdateStatus.checking ||
        s == DataUpdateStatus.error) {
      return const SizedBox.shrink();
    }
    if (s == DataUpdateStatus.applied && service.updateBannerDismissed) {
      return const SizedBox.shrink();
    }

    final isDownloading = s == DataUpdateStatus.downloading;
    final bg = isDownloading
        ? (isDark ? Colors.blueGrey.shade800 : const Color(0xFFE3F2FD))
        : (isDark ? Colors.green.shade900 : const Color(0xFFE8F5E9));
    final fg = isDownloading
        ? (isDark ? Colors.white : const Color(0xFF0D47A1))
        : (isDark ? Colors.white : const Color(0xFF1B5E20));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isDownloading ? Icons.cloud_download_outlined : Icons.check_circle,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDownloading
                      ? 'กำลังอัพเดทคำศัพท์...'
                      : 'อัพเดทคำศัพท์เรียบร้อย',
                  style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: service.updateProgress > 0
                            ? service.updateProgress
                            : null,
                        minHeight: 3,
                        backgroundColor: fg.withOpacity(0.15),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isDownloading)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close, size: 18, color: fg),
              onPressed: service.dismissUpdateBanner,
            ),
        ],
      ),
    );
  }
}