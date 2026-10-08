import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import 'add_property_screen.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    setState(() { _properties = data; _isLoading = false; });
  }

  Future<void> _deleteProperty(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تایید حذف'),
          content: const Text('آیا از حذف این ملک مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteProperty(id);
      _loadProperties();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ ملک حذف شد'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num priceNum = price is int ? price : (price is double ? price.toInt() : 0);
    return priceNum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'آپارتمان': return Colors.blue;
      case 'ویلا': return Colors.green;
      case 'زمین': return Colors.orange;
      case 'تجاری': return Colors.purple;
      case 'مغازه': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست املاک'),
        backgroundColor: Colors.blue[700],
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProperties)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_work, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('هنوز ملکی ثبت نشده', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final p = _properties[index];
                    List<String> images = [];
                    if (p['images'] != null && p['images'] != '') {
                      try {
                        final List<dynamic> paths = jsonDecode(p['images']);
                        images = paths.cast<String>();
                      } catch (e) {
                        print('Error parsing images: $e');
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // نمایش عکس‌ها
                              if (images.isNotEmpty) ...[
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    itemBuilder: (ctx, i) {
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(File(images[i]), height: 150, fit: BoxFit.cover),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _getTypeColor(p['type'] ?? '').withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text(p['type'] ?? '', style: TextStyle(color: _getTypeColor(p['type'] ?? ''), fontWeight: FontWeight.bold)),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: p['status'] == 'available' ? Colors.green[100] : Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                                    child: Text(p['status'] == 'available' ? 'موجود' : 'فروخته شده', style: TextStyle(color: p['status'] == 'available' ? Colors.green[800] : Colors.grey[700], fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(p['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${p['area']} متر'),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('${_formatPrice(p['price'])} تومان', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(p['address'] ?? '', style: TextStyle(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              if (p['owner_name'] != null && (p['owner_name'] as String).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('مالک: ${p['owner_name']}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AddPropertyScreen(propertyId: p['id'])),
                                        );
                                        if (result == true) _loadProperties();
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('ویرایش'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _deleteProperty(p['id']),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('حذف'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
          if (result == true) _loadProperties();
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('ثبت ملک جدید'),
      ),
    );
  }
}
