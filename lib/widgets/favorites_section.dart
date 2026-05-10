import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puridict/services/dictionary_service.dart';

class FavoritesSection extends StatefulWidget {
  const FavoritesSection({Key? key}) : super(key: key);

  @override
  State<FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends State<FavoritesSection> {
  bool _showFavorites = false;

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DictionaryService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (service.favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    // ใช้ SingleChildScrollView ครอบ Column เพื่อให้สามารถ scroll ได้
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_showFavorites)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4, left: 16, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'รายการโปรด',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.keyboard_arrow_up,
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFavorites = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: service.favorites.length,
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final favorite = service.favorites[index];
                      return ListTile(
                        title: Text(
                          favorite.headword,
                          style: TextStyle(
                            color: isDarkMode 
                                ? Colors.white 
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => service.toggleFavorite(favorite),
                        ),
                        onTap: () {
                          service.setSearchQuery(favorite.headword);
                          service.performSearch();
                        },
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.favorite, color: Colors.red),
                label: Text(
                  'แสดงรายการโปรด (${service.favorites.length})',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : null,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _showFavorites = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}