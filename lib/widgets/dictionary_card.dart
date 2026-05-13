import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puridict/models/dictionary_entry.dart';
import 'package:puridict/services/dictionary_service.dart';

class DictionaryCard extends StatefulWidget {
  final DictionaryEntry entry;
  final bool isTopResult;
  final double fontSize;

  const DictionaryCard({
    Key? key,
    required this.entry,
    this.isTopResult = false,
    required this.fontSize,
  }) : super(key: key);

  @override
  State<DictionaryCard> createState() => _DictionaryCardState();
}

class _EtyBlockData {
  final String part;
  final String role;
  final String? meaning;
  const _EtyBlockData({required this.part, required this.role, this.meaning});
}

class _RoleStyle {
  final Color bg;
  final Color border;
  final Color text;
  final Color sub;
  const _RoleStyle(this.bg, this.border, this.text, this.sub);
}

class _DictionaryCardState extends State<DictionaryCard> {
  bool _showDetails = false;

  static final Map<String, _RoleStyle> _roleStyles = {
    'ธาตุ': _RoleStyle(
      Color(0xFFFCE4EC),
      Color(0xFFEC407A),
      Color(0xFFAD1457),
      Color(0xFFC2185B),
    ),
    'ปัจจัย': _RoleStyle(
      Color(0xFFE3F2FD),
      Color(0xFF42A5F5),
      Color(0xFF1565C0),
      Color(0xFF1976D2),
    ),
    'วิภัตติ': _RoleStyle(
      Color(0xFFE8F5E9),
      Color(0xFF66BB6A),
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
    ),
    'บทหน้า': _RoleStyle(
      Color(0xFFFFF3E0),
      Color(0xFFFFA726),
      Color(0xFFE65100),
      Color(0xFFEF6C00),
    ),
    'อาคม': _RoleStyle(
      Color(0xFFF3E5F5),
      Color(0xFFAB47BC),
      Color(0xFF6A1B9A),
      Color(0xFF7B1FA2),
    ),
  };

  static final _RoleStyle _roleDefault = _RoleStyle(
    Color(0xFFF5F5F5),
    Color(0xFFBDBDBD),
    Color(0xFF424242),
    Color(0xFF616161),
  );

  _RoleStyle _styleFor(String role) {
    for (final entry in _roleStyles.entries) {
      if (role.contains(entry.key)) return entry.value;
    }
    return _roleDefault;
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DictionaryService>(context);
    final entry = widget.entry;
    final isFavorite = service.isFavorite(entry);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fs = widget.fontSize;
    final hasAnyDetail = _hasAnyDetail(entry);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    final accentColors = widget.isTopResult
        ? [secondary, const Color(0xFFFFB77D)] // orange → peach
        : const [
            Color(0xFF1E3A8A), // royal blue
            Color(0xFF3730A3), // regal indigo
          ];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Theme.of(context).cardColor, Theme.of(context).cardColor]
              : [
                  Theme.of(context).cardColor,
                  Color.alphaBlend(primary.withOpacity(0.025),
                      Theme.of(context).cardColor),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (widget.isTopResult ? secondary : primary)
                .withOpacity(isDarkMode ? 0.0 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient left bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: accentColors,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.headword,
                        style: TextStyle(
                          fontSize: (fs + 0.4) * 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _headerChips(context, entry),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  iconSize: 20,
                  onPressed: () => service.toggleFavorite(entry),
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                ),
              ],
            ),
          ),

          // ความหมายหลัก
          if (entry.glossTh.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ความหมาย',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.glossTh,
                    style: TextStyle(
                      fontSize: fs * 17,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (hasAnyDetail && _showDetails) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 24),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDetailSections(context, entry, fs, isDark),
              ),
            ),
          ] else
            const SizedBox(height: 8),

          // Bottom row: top-result badge (left) + collapse icon (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isTopResult)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFE932C), // secondary (orange)
                          Color(0xFFFFB77D), // peach
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFE932C).withOpacity(0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.white, size: 11),
                        SizedBox(width: 4),
                        Text(
                          'ตรงกับคำค้นหามากที่สุด',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (hasAnyDetail) _buildCollapseIcon(context, isDark),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  // ─── Header chips ───────────────────────────────────────────

  List<Widget> _headerChips(BuildContext context, DictionaryEntry entry) {
    final chips = <Widget>[];
    if (entry.categoryFull != null) {
      chips.add(_pill(
        icon: Icons.label_outline,
        label: entry.categoryFull!,
        bg: const Color(0xFFE8EAF6),
        fg: const Color(0xFF3949AB),
      ));
    }
    final root = entry.effectiveVerbRoot;
    if (root != null) {
      final mean = root.meaning;
      final label = (mean != null && mean.isNotEmpty)
          ? '${root.root} [$mean]'
          : root.root;
      chips.add(_pill(
        icon: Icons.spa_outlined,
        label: label,
        bg: const Color(0xFFFFF8E1),
        fg: const Color(0xFFB28704),
      ));
    }
    final ety = entry.etymology;
    if (ety != null) {
      for (final p in ety.paccaya) {
        chips.add(_pill(
          icon: Icons.auto_awesome_outlined,
          label: p,
          bg: const Color(0xFFF3E5F5),
          fg: const Color(0xFF6A1B9A),
        ));
      }
    }
    if (entry.genderFull != null) {
      chips.add(_pill(
        icon: Icons.transgender_outlined,
        label: entry.genderFull!,
        bg: const Color(0xFFE0F2F1),
        fg: const Color(0xFF00695C),
      ));
    }
    return chips;
  }

  Widget _buildCollapseIcon(BuildContext context, bool isDark) {
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _showDetails = !_showDetails),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? primary.withOpacity(0.3)
                : primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _showDetails
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: isDark ? Colors.white : primary,
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── Detail sections ────────────────────────────────────────

  bool _hasAnyDetail(DictionaryEntry e) {
    return e.source.volumes != null ||
        _hasEtymologyBlocks(e) ||
        e.vigraha != null ||
        e.grammar?.compoundType != null ||
        e.grammar?.saadhana != null ||
        e.examples.isNotEmpty ||
        e.declensionSample != null ||
        e.seeAlso.isNotEmpty ||
        (e.note != null && e.note!.isNotEmpty) ||
        (e.meaningsOriginal != null && e.meaningsOriginal!.isNotEmpty);
  }

  List<Widget> _buildDetailSections(
      BuildContext context, DictionaryEntry entry, double fs, bool isDark) {
    final out = <Widget>[];

    if (entry.source.volumes != null) {
      out.add(_volumeChip(context, entry.source.volumes!));
      out.add(const SizedBox(height: 14));
    }

    if (_hasEtymologyBlocks(entry)) {
      out.add(_section(
        context,
        icon: Icons.account_tree_outlined,
        title: 'โครงสร้างคำ',
        accent: Theme.of(context).primaryColor,
        child: _etymologyBlocks(context, entry, fs),
      ));
      out.add(const SizedBox(height: 12));
    }

    if (entry.vigraha != null ||
        entry.grammar?.compoundType != null ||
        entry.grammar?.saadhana != null) {
      out.add(_section(
        context,
        icon: Icons.zoom_in_outlined,
        title: 'บทวิเคราะห์',
        accent: const Color(0xFF6A1B9A),
        child: _vigrahaBody(context, entry, fs, isDark),
      ));
      out.add(const SizedBox(height: 12));
    }

    if (entry.examples.isNotEmpty || entry.declensionSample != null) {
      out.add(_section(
        context,
        icon: Icons.grid_view_outlined,
        title: 'การแจกวิภัตติ',
        accent: const Color(0xFF00838F),
        child: _declensionBody(context, entry, fs, isDark),
      ));
      out.add(const SizedBox(height: 12));
    }

    if (entry.seeAlso.isNotEmpty) {
      final service = Provider.of<DictionaryService>(context, listen: false);
      out.add(_section(
        context,
        icon: Icons.link_rounded,
        title: 'คำที่เกี่ยวข้อง',
        accent: const Color(0xFF1565C0),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: entry.seeAlso
              .map((w) => InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      service.setSearchQuery(w);
                      service.performSearch();
                    },
                    child: _seeAlsoChip(context, w, fs),
                  ))
              .toList(),
        ),
      ));
      out.add(const SizedBox(height: 12));
    }

    if (entry.note != null && entry.note!.isNotEmpty) {
      out.add(_section(
        context,
        icon: Icons.sticky_note_2_outlined,
        title: 'หมายเหตุ',
        accent: const Color(0xFFE65100),
        child: Text(entry.note!,
            style: TextStyle(fontSize: fs * 14, height: 1.6)),
      ));
      out.add(const SizedBox(height: 12));
    }

    return out;
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color accent,
    Widget? trailing,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: accent.withOpacity(isDark ? 0.4 : 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: accent)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _volumeChip(BuildContext context, String volumes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Theme.of(context).dividerColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book,
              size: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(width: 6),
          Text('ธมฺมปท ภาค $volumes',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  // ─── บทวิเคราะห์ (vigraha) ──────────────────────────────────

  Widget _vigrahaBody(
      BuildContext context, DictionaryEntry entry, double fs, bool isDark) {
    const accent = Color(0xFF6A1B9A);
    final chain = entry.grammar?.compoundChain ?? const [];
    final hasChain = chain.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── ประเภท: pill ───────────────────────────────
        if (entry.grammar?.compoundType != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text('ประเภท:',
                    style: TextStyle(
                        fontSize: fs * 12,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _composeCompoundTypeLabel(entry),
                    style: TextStyle(
                      fontSize: fs * 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // ─── สมาสซ้อน: render เป็น step cards ─────────────
        if (hasChain)
          ...chain.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _compoundStepCard(context, s, fs, isDark, accent),
              ))
        // ─── สมาสเดี่ยว: render vigraha block แบบเดิม ─────
        else if (entry.vigraha != null)
          _vigrahaBlock(context, entry.vigraha!, fs, isDark, accent),
        if (entry.grammar?.saadhana != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              entry.grammar!.saadhana!,
              style: TextStyle(
                fontSize: fs * 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }

  /// สร้างข้อความ "ประเภท:" — ถ้ามีสมาสซ้อนจะรวมข้อมูล inner ด้วย
  /// เช่น "ฉัฏฐีตุลยาธิกรณพหุพพิหิสมาส มี อสมาหาร ทวันทวสมาส เป็นภายใน"
  String _composeCompoundTypeLabel(DictionaryEntry entry) {
    final outer = entry.grammar?.compoundType ?? '';
    final chain = entry.grammar?.compoundChain ?? const [];
    if (chain.length < 2) return outer;
    final innerTypes =
        chain.where((s) => s.internal).map((s) => s.type).toList();
    if (innerTypes.isEmpty) return outer;
    return '$outer มี ${innerTypes.join(', ')} เป็นภายใน';
  }

  Widget _vigrahaBlock(BuildContext context, String vigraha, double fs,
      bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'วิ. ',
            style: TextStyle(
              fontSize: fs * 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : accent,
            ),
          ),
          Expanded(
            child: Text(vigraha,
                style: TextStyle(fontSize: fs * 15, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _compoundStepCard(BuildContext context, CompoundStep s, double fs,
      bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (s.abbr.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.30 : 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.abbr,
                    style: TextStyle(
                      fontSize: fs * 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : accent,
                    ),
                  ),
                ),
              if (s.type.isNotEmpty)
                Text(
                  s.type,
                  style: TextStyle(
                    fontSize: fs * 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (s.internal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'เป็นภายใน',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB28704),
                    ),
                  ),
                ),
            ],
          ),
          if (s.vigraha != null && s.vigraha!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'วิ. ',
                    style: TextStyle(
                      fontSize: fs * 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : accent,
                    ),
                  ),
                  Expanded(
                    child: Text(s.vigraha!,
                        style: TextStyle(fontSize: fs * 15, height: 1.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── การแจกวิภัตติ ──────────────────────────────────────────

  Widget _declensionBody(
      BuildContext context, DictionaryEntry entry, double fs, bool isDark) {
    const accent = Color(0xFF00838F);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.declensionSample != null)
          Padding(
            padding: EdgeInsets.only(
                bottom: entry.examples.isNotEmpty ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.menu, size: 14, color: accent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'แบบแจก: ',
                          style: TextStyle(
                            fontSize: fs * 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                        TextSpan(
                          text: 'แจกเหมือน ${entry.declensionSample}',
                          style: TextStyle(
                            fontSize: fs * 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        if (entry.examples.isNotEmpty)
          Column(
            children: entry.examples
                .map((ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _exampleCard(context, ex, fs, isDark, accent),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _exampleCard(BuildContext context, Example ex, double fs, bool isDark,
      Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (ex.caseName != null && ex.caseName!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ex.caseName!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fs * 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (ex.caseName != null && ex.caseName!.isNotEmpty)
                const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ex.form ?? '',
                  style: TextStyle(
                      fontSize: fs * 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (ex.glossTh != null && ex.glossTh!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                ex.glossTh!,
                style: TextStyle(
                  fontSize: fs * 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── โครงสร้างคำ ────────────────────────────────────────────

  bool _hasEtymologyBlocks(DictionaryEntry e) =>
      _collectEtymologyBlocks(e).isNotEmpty;

  List<_EtyBlockData> _collectEtymologyBlocks(DictionaryEntry entry) {
    final out = <_EtyBlockData>[];
    final ety = entry.etymology;

    // เริ่มด้วย ธาตุ ถ้ามี (ใช้ effectiveVerbRoot — fallback ไป parse note/original)
    final root = entry.effectiveVerbRoot;
    bool componentsHasDhatu = false;
    if (ety != null && ety.components.isNotEmpty) {
      componentsHasDhatu =
          ety.components.any((c) => (c.role ?? '').contains('ธาตุ'));
    }
    if (root != null && !componentsHasDhatu) {
      out.add(_EtyBlockData(
        part: root.root,
        role: 'ธาตุ',
        meaning: root.meaning,
      ));
    }

    if (ety != null) {
      if (ety.components.isNotEmpty) {
        for (final c in ety.components) {
          final part = c.part ?? '';
          if (part.isEmpty) continue;
          out.add(_EtyBlockData(
            part: part,
            role: c.role ?? '',
            meaning: c.meaning ?? c.note,
          ));
        }
      } else {
        for (final p in ety.paccaya) {
          // paccaya มักเขียนเป็น "ยุ ปัจจัย" — ตัด "ปัจจัย" ออกถ้ามี
          final cleanPart = p.replaceFirst(RegExp(r'\s*ปัจจัย\s*$'), '');
          out.add(_EtyBlockData(part: cleanPart, role: 'ปัจจัย'));
        }
      }
    }

    return out;
  }

  Widget _etymologyBlocks(
      BuildContext context, DictionaryEntry entry, double fs) {
    final blocks = _collectEtymologyBlocks(entry);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      children.add(_etyBlock(context, blocks[i], fs));
      if (i < blocks.length - 1) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('+',
              style: TextStyle(
                fontSize: fs * 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
        ));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _etyBlock(BuildContext context, _EtyBlockData data, double fs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _styleFor(data.role);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? s.bg.withOpacity(0.18) : s.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? s.border.withOpacity(0.7) : s.border,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.part,
              style: TextStyle(
                fontSize: fs * 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : s.text,
              ),
            ),
            if (data.role.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  data.role,
                  style: TextStyle(
                    fontSize: fs * 11,
                    color: isDark ? s.border : s.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (data.meaning != null && data.meaning!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '"${data.meaning}"',
                  style: TextStyle(
                    fontSize: fs * 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? s.border : s.sub,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── small chips ────────────────────────────────────────────

  Widget _seeAlsoChip(BuildContext context, String label, double fs) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: fs * 13,
            color: primary,
            fontWeight: FontWeight.w600),
      ),
    );
  }

}
