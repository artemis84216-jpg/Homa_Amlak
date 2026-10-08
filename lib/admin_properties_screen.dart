import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import 'app_utils.dart';
import 'property_image_gallery.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus == 'sold' ? '✓ وضعیت به فروخته شده تغییر کرد' : '✓ وضعیت به موجود تغییر کرد'), backgroundColor: AppTheme.gold));
  }

  Future<void> _togglePublic(int id, bool currentIsPublic) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('properties', {'is_public': currentIsPublic ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
    _loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت املاک'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadProperties)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _properties.isEmpty ? Center(child: Text('هنوز ملکی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))) : ListView.builder(
        padding: const EdgeInsets.all(12), 
        itemCount: _properties.length, 
        itemBuilder: (context, index) {
          final p = _properties[index];
          final isPublic = p['is_public'] == 1 || p['is_public'] == true;
          final listingType = p['listing_type'] == 'rent' ? 'اجاره' : 'فروش';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12), 
            child: Directionality(
              textDirection: TextDirection.rtl, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  PropertyImageGallery(imagesJson: p['images'], height: 150, showCounter: false),
                  Padding(
                    padding: const EdgeInsets.all(12), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: p['listing_type'] == 'rent' ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: p['listing_type'] == 'rent' ? Colors.blue : Colors.green)), child: Text(listingType, style: TextStyle(color: p['listing_type'] == 'rent' ? Colors.blue : Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)), child: Text(p['type'] ?? '', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12))),
                            const Spacer(),
                            IconButton(
                              icon: Icon(isPublic ? Icons.visibility : Icons.visibility_off, color: isPublic ? AppTheme.gold : AppTheme.textGrey, size: 20), 
                              onPressed: () => _togglePublic(p['id'], isPublic), 
                              tooltip: isPublic ? 'مخفی کردن از مشتری' : 'نمایش به مشتری'
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(p['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.square_foot, size: 16, color: AppTheme.textGrey),
                            const SizedBox(width: 4),
                            Text('${formatNumber((p['area'] ?? 0).toInt())} متر', style: const TextStyle(color: AppTheme.textWhite)),
                            const SizedBox(width: 8),
                            const Icon(Icons.bed, size: 16, color: AppTheme.textGrey),
                            const SizedBox(width: 4),
                            Text('${formatNumber((p['bedrooms'] ?? 0).toInt())} خواب', style: const TextStyle(color: AppTheme.textWhite)),
                            const SizedBox(width: 16),
                            const Icon(Icons.attach_money, size: 16, color: AppTheme.textGrey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('${formatPrice(p['price'])} تومان', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textYellow))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBlack,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gold, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge, size: 16, color: AppTheme.gold),
                              const SizedBox(width: 6),
                              Expanded(child: Text('مشاور: ${p['agent_name'] ?? 'نامشخص'}', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _changeStatus(p['id'], p['status'] == 'available' ? 'sold' : 'available'), 
                          icon: Icon(p['status'] == 'available' ? Icons.sell : Icons.undo, size: 18), 
                          label: Text(p['status'] == 'available' ? 'تغییر به فروخته شده' : 'تغییر به موجود', style: const TextStyle(fontSize: 14)), 
                          style: ElevatedButton.styleFrom(backgroundColor: p['status'] == 'available' ? Colors.red : Colors.green, foregroundColor: Colors.white),
                        ),
                      ]
                    )
                  ),
                ]
              )
            )
          );
        }
      ),
    );
  }
}
