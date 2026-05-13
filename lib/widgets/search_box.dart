import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puridict/services/dictionary_service.dart';
import 'package:puridict/theme/app_theme.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({Key? key}) : super(key: key);

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final service = Provider.of<DictionaryService>(context, listen: false);
    _controller = TextEditingController(text: service.searchQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); 
    super.dispose();
  }
  
  void _clearAndFocus() {
    // ล้างค่าใน controller
    _controller.clear();
    // เรียกใช้ clearSearch ของ service
    Provider.of<DictionaryService>(context, listen: false).clearSearch();
    // แยก setState ออกมาชัดเจน
    setState(() {});
    // ดีเลย์เล็กน้อยก่อนให้ focus
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DictionaryService>(context);
    
    // อัพเดท controller เมื่อ service.searchQuery เปลี่ยนแปลงจากภายนอก
    // แต่รักษาตำแหน่ง cursor ไว้
    if (_controller.text != service.searchQuery && !_controller.text.contains(service.searchQuery)) {
      final currentPosition = _controller.selection.base.offset;
      _controller.text = service.searchQuery;
      // ตั้งค่า cursor ไว้ที่ตำแหน่งเดิมหรือปลายสุดถ้าเกินความยาวข้อความ
      if (currentPosition > _controller.text.length) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length)
        );
      } else if (currentPosition >= 0) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition)
        );
      }
    }

    return Container(
      // margin: const EdgeInsets.only(bottom: 16),
      margin:  const EdgeInsets.only(
        bottom: 6,
        left: 16,
        right: 16,
      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          // จัดการกับ cursor และการแสดงผลภาษาไทย
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          // ปิดคุณสมบัติที่อาจรบกวนการพิมพ์ภาษาไทย
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (value) {
                            // เก็บตำแหน่ง cursor ปัจจุบัน
                            final cursorPos = _controller.selection.base.offset;
                            // อัพเดทค่าใน service
                            service.setSearchQuery(value);
                            // คงตำแหน่ง cursor ไว้
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: cursorPos)
                            );
                          },
                          onSubmitted: (_) {
                            // ปิดแป้นพิมพ์
                            FocusScope.of(context).unfocus();
                            service.performSearch();
                          },
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: service.dictionaryType == 'paliThai'
                                ? '🔍 ค้นหาจากบาลี...'
                                : '🔍 ค้นหาจากไทย...',
                            hintStyle: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (service.searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearAndFocus, // เรียกใช้เมธอดใหม่
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _GradientSearchButton(
                enabled: service.searchQuery.isNotEmpty,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  service.performSearch();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientSearchButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _GradientSearchButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // โทนเดียวกับ header — vibrant royal blue
    final activeColors = isDark
        ? const [Color(0xFF1E3A8A), Color(0xFF2851B8)]
        : const [
            Color(0xFF1E3A8A),
            Color(0xFF2851B8),
            Color(0xFF3B6FE0),
          ];
    // disabled: pastel royal — ยังเป็นน้ำเงินสดใส แค่ lighter
    final disabledColors = isDark
        ? const [Color(0xFF3A5499), Color(0xFF4E6BB8)]
        : const [
            Color(0xFF7B98D8),
            Color(0xFF94B0E8),
            Color(0xFFB0C5EF),
          ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.4),
          end: const Alignment(1.0, 1.0),
          colors: enabled ? activeColors : disabledColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: [
              Colors.white.withOpacity(0.14),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(
                  'ค้นหา',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ),
      );
  }
}

