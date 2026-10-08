import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import 'add_property_screen.dart';
import 'app_utils.dart';
import 'property_image_gallery.dart';

class PropertiesListScreen extends StatefulWidget {
  final Map<String, dynamic>? currentAgent;
  const PropertiesListScreen({super.key, this.currentAgent});

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
    final allData = await DatabaseHelper.instance.getAllProperties();
    
    // اگر مشاور وارد شده باشد، فقط املاک خودش را نشان بده
    if (widget.currentAgent != null) {
      _properties = allData.where((p) => p['agent_name'] == widget.currentAgent!['name']).toList();
    } else {
      _properties = allData; // برای مدیر (در فازهای بعدی)
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _deleteProperty(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا از حذف این ملک مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('لیست املاک'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadProperties)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_work, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز ملکی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final p = _properties[index];
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)),
                                        child: Text(p['type'] ?? '', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: p['status'] == 'available' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Text(p['status'] == 'available' ? 'موجود' : 'فروخته شده', style: TextStyle(color: p['status'] == 'available' ? Colors.green : Colors.grey, fontSize: 12)),
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
                                      const SizedBox(width: 16),
                                      const Icon(Icons.attach_money, size: 16, color: AppTheme.textGrey),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text('${formatPrice(p['price'])} تومان', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textYellow))),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(propertyId: p['id'], currentAgent: widget.currentAgent)));
                                            if (result == true) _loadProperties();
                                          },
                                          icon: const Icon(Icons.edit, size: 18),
                                          label: const Text('ویرایش', style: TextStyle(fontSize: 14)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _deleteProperty(p['id']),
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text('حذف', style: TextStyle(fontSize: 14)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(currentAgent: widget.currentAgent)));
          if (result == true) _loadProperties();
        },
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ثبت ملک جدید'),
      ),
    );
  }
}
