import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'property_detail_screen.dart';

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
        bool matchesSearch = p['title'].toString().toLowerCase().contains(query) ||
                             p['address'].toString().toLowerCase().contains(query);
        bool matchesType = _selectedType == 'همه' || p['type'] == _selectedType;
        bool isAvailable = p['status'] == 'available'; // مشتری فقط املاک موجود را ببیند
        return matchesSearch && matchesType && isAvailable;
      }).toList();
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '۰';
    final num priceNum = price is int ? price : (price is double ? price.toInt() : 0);
    String formatted = priceNum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return formatted.replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲')
        .replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵')
        .replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸')
        .replaceAll('9', '۹');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جستجوی املاک'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
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
                    decoration: InputDecoration(
                      hintText: 'جستجو در عنوان یا آدرس...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            })
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
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
                            onSelected: (selected) {
                              setState(() => _selectedType = type);
                              _applyFilters();
                            },
                            selectedColor: Colors.blue[100],
                            checkmarkColor: Colors.blue[700],
                            labelStyle: TextStyle(color: isSelected ? Colors.blue[800] : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProperties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('ملکی با این مشخصات یافت نشد', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProperties[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home, color: Colors.grey, size: 40),
                                    // نکته: برای نمایش عکس واقعی می‌توان کد Image.file را اینجا گذاشت، اما برای سرعت لیست، آیکون کافی است.
                                  ),
                                ),
                                title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${p['area']} متر | ${p['type']}', style: TextStyle(color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text('${_formatPrice(p['price'])} تومان', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)),
                                  );
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
