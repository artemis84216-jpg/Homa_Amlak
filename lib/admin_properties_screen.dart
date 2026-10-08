import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
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

  Future<void> _changeStatus(int id, String newStatus) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('properties', {'status': newStatus}, where: 'id = ?', whereArgs: [id]);
    _loadProperties();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'sold' ? '✓ وضعیت به فروخته شده تغییر کرد' : '✓ وضعیت به موجود تغییر کرد'),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const Text('مدیریت املاک'),
        backgroundColor: Colors.indigo[700],
        centerTitle: true,       // وسط‌چین
        foregroundColor: Colors.white, // سفید
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProperties)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? Center(child: Text('هنوز ملکی ثبت نشده', style: TextStyle(fontSize: 18, color: Colors.grey[600])))
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
                      } catch (e) {}
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
                              if (images.isNotEmpty)
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    itemBuilder: (ctx, i) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(File(images[i]), height: 120, fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                ),
                              if (images.isNotEmpty) const SizedBox(height: 12),
                              Text(p['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('${_formatPrice(p['price'])} تومان', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _changeStatus(p['id'], p['status'] == 'available' ? 'sold' : 'available'),
                                icon: Icon(p['status'] == 'available' ? Icons.sell : Icons.undo),
                                label: Text(p['status'] == 'available' ? 'تغییر به فروخته شده' : 'تغییر به موجود'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: p['status'] == 'available' ? Colors.red : Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
