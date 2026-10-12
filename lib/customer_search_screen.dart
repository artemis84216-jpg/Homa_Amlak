import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import 'property_detail_screen.dart';
import 'app_utils.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  List<Map<String, dynamic>> _allProperties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'همه';
  final List<String> _types = ['همه', 'آپارتمان', 'ویلا', 'زمین', 'تجاری', 'مغازه'];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    setState(() {
      _allProperties = data;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProperties = _allProperties.where((p) {
        bool matchesSearch = p['title'].toString().toLowerCase().contains(query) || p['address'].toString().toLowerCase().contains(query);
        bool matchesType = _selectedType == 'همه' || p['type'] == _selectedType;
        bool isAvailable = p['status'] == 'available';
        bool isPublic = p['is_public'] == 1 || p['is_public'] == true;
        return matchesSearch && matchesType && isAvailable && isPublic;
      }).toList();
    });
  }

  void _showFullScreenImage(String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('جستجوی املاک'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'جستجو در عنوان یا آدرس...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _applyFilters(); })
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _types.length,
                      itemBuilder: (context, index) {
                        final type = _types[index];
                        final isSelected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) { setState(() => _selectedType = type); _applyFilters(); },
                            selectedColor: AppTheme.gold,
                            backgroundColor: AppTheme.cardBlack,
                            checkmarkColor: Colors.black,
                            labelStyle: TextStyle(color: isSelected ? Colors.black : AppTheme.gold, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                            side: const BorderSide(color: AppTheme.gold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.gold),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                  : _filteredProperties.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: AppTheme.textGrey), const SizedBox(height: 16), Text('ملکی با این مشخصات یافت نشد', style: TextStyle(color: AppTheme.textGrey, fontSize: 16))]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProperties[index];
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
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // نمایش همه عکس‌ها به صورت مربعی در کنار هم
                                        if (images.isNotEmpty) ...[
                                          SizedBox(
                                            height: 100,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: images.length,
                                              itemBuilder: (ctx, i) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 8),
                                                  child: GestureDetector(
                                                    onTap: () => _showFullScreenImage(images[i]),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.file(
                                                        File(images[i]),
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ] else ...[
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardBlack,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                                            ),
                                            child: const Icon(Icons.home, color: AppTheme.textGrey, size: 40),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)),
                                              child: Text(p['type'] ?? '', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: p['listing_type'] == 'rent' ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: p['listing_type'] == 'rent' ? Colors.blue : Colors.green)),
                                              child: Text(p['listing_type'] == 'rent' ? 'اجاره' : 'فروش', style: TextStyle(color: p['listing_type'] == 'rent' ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const Spacer(),
                                            if (images.length > 1)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.photo_library, color: AppTheme.gold, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text('${toPersianDigits(images.length.toString())} عکس', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textWhite)),
                                        const SizedBox(height: 4),
                                        Text('${formatNumber((p['area'] ?? 0).toInt())} متر | ${formatNumber((p['bedrooms'] ?? 0).toInt())} خواب', style: const TextStyle(color: AppTheme.textGrey)),
                                        const SizedBox(height: 8),
                                        Text('${formatPrice(p['price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
