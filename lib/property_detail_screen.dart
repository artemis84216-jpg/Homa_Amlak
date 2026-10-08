import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

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
    List<String> images = [];
    if (property['images'] != null && property['images'] != '') {
      try {
        final List<dynamic> paths = jsonDecode(property['images']);
        images = paths.cast<String>();
      } catch (e) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات ملک'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.file(File(images[index]), fit: BoxFit.cover);
                    },
                  ),
                )
              else
                Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.home_work, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 4),
                        Text(property['type'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: property['status'] == 'available' ? Colors.green[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            property['status'] == 'available' ? 'موجود' : 'فروخته شده',
                            style: TextStyle(color: property['status'] == 'available' ? Colors.green[800] : Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(Icons.square_foot, 'متراژ', '${property['area']} متر مربع'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.attach_money, 'قیمت', '${_formatPrice(property['price'])} تومان', isPrice: true),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'آدرس', property['address'] ?? 'بدون آدرس'),
                    const Divider(height: 32),
                    const Text('مشخصات مالک', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'نام مالک', property['owner_name'] ?? 'ثبت نشده'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'شماره تماس', property['owner_phone'] ?? 'ثبت نشده'),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: property['status'] == 'available' && property['owner_phone'] != null
                            ? () {
                                // اینجا می‌توان بعداً قابلیت تماس یا ارسال پیامک را اضافه کرد
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('شماره تماس: ${property['owner_phone']}')),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.phone, size: 24),
                        label: const Text('تماس با مالک', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPrice ? Colors.green[800] : Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
