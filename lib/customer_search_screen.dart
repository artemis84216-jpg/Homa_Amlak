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

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: Image.file(File(imagePath), fit: BoxFit.contain)),
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
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : AppTheme.gold,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 64, color: AppTheme.textGrey),
                              const SizedBox(height: 16),
                              Text('ملکی با این مشخصات یافت نشد', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
                            ],
                          ),
                        )
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
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: GestureDetector(
                                  onTap: images.isNotEmpty ? () => _showFullImage(context, images[0]) : null,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: images.isNotEmpty
                                        ? Image.file(File(images[0]), width: 80, height: 80, fit: BoxFit.cover)
                                        : Container(width: 80, height: 80, color: AppTheme.cardBlack, child: const Icon(Icons.home, color: AppTheme.textGrey, size: 40)),
                                  ),
                                ),
                                title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${formatNumber((p['area'] ?? 0).toInt())} متر | ${p['type']}', style: const TextStyle(color: AppTheme.textGrey)),
                                    const SizedBox(height: 4),
                                    Text('${formatPrice(p['price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_left, color: AppTheme.gold),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
                                },
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
