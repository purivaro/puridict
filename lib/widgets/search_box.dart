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
              Container(
                height: 48,
                child: ElevatedButton(
                  onPressed: service.searchQuery.isEmpty
                      ? null
                      : () {
                        FocusScope.of(context).unfocus();
                        service.performSearch();
                      },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    
                    backgroundColor: (Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.darkHeaderColor  
                      : Theme.of(context).primaryColor),
                  ),
                  child: const Text('ค้นหา'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}