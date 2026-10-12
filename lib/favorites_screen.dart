import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'property_detail_screen.dart';
import 'app_utils.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_property_ids') ?? [];
    
    if (favIds.isEmpty) {
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
      return;
    }

    final allProperties = await DatabaseHelper.instance.getAllProperties();
    final favList = allProperties.where((p) => favIds.contains(p['id'].toString())).toList();
    
    setState(() {
      _favorites = favList;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(int propertyId) async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_property_ids') ?? [];
    favIds.remove(propertyId.toString());
    await prefs.setStringList('favorite_property_ids', favIds);
    _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ از علاقه‌مندی‌ها حذف شد'), backgroundColor: AppTheme.gold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('علاقه‌مندی‌های من'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadFavorites)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز ملکی به علاقه‌مندی‌ها اضافه نکرده‌اید', style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
                      const SizedBox(height: 8),
                      Text('با کلیک روی آیکون قلب در صفحه جزئیات ملک، آن را به علاقه‌مندی‌ها اضافه کنید', style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final p = _favorites[index];
                    List<String> images = [];
                    if (p['images'] != null && p['images'] != '') {
                      try {
                        final List<dynamic> paths = jsonDecode(p['images']);
                        images = paths.cast<String>();
                      } catch (e) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p))),
                        borderRadius: BorderRadius.circular(12),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: images.isNotEmpty
                                      ? Image.file(File(images[0]), width: 100, height: 100, fit: BoxFit.cover)
                                      : Container(width: 100, height: 100, color: AppTheme.cardBlack, child: const Icon(Icons.home, color: AppTheme.textGrey, size: 40)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textWhite)),
                                      const SizedBox(height: 4),
                                      Text('${p['type']} | ${formatNumber((p['area'] ?? 0).toInt())} متر', style: const TextStyle(color: AppTheme.textGrey)),
                                      const SizedBox(height: 8),
                                      Text('${formatPrice(p['price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                                  onPressed: () => _removeFavorite(p['id']),
                                  tooltip: 'حذف از علاقه‌مندی‌ها',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
