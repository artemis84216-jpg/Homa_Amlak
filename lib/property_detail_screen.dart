import 'package:flutter/material.dart';
import 'app_utils.dart';
import 'property_image_gallery.dart'; // <-- این خط اضافه شد

class PropertyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('جزئیات ملک'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // استفاده از گالری جدید
              PropertyImageGallery(imagesJson: property['images']),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property['title'] ?? '',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_work, color: AppTheme.gold, size: 20),
                        const SizedBox(width: 4),
                        Text(property['type'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textYellow)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: property['status'] == 'available' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: property['status'] == 'available' ? Colors.green : Colors.grey),
                          ),
                          child: Text(
                            property['status'] == 'available' ? 'موجود' : 'فروخته شده',
                            style: TextStyle(
                              color: property['status'] == 'available' ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppTheme.gold),
                    _buildInfoRow(Icons.square_foot, 'متراژ', '${formatNumber((property['area'] ?? 0).toInt())} متر مربع'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.attach_money, 'قیمت', '${formatPrice(property['price'])} تومان', isPrice: true),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'آدرس', property['address'] ?? 'بدون آدرس'),
                    const Divider(height: 32, color: AppTheme.gold),
                    const Text('مشخصات مالک', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'نام مالک', property['owner_name'] ?? 'ثبت نشده'),
                    const Divider(height: 32, color: AppTheme.gold),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge, color: AppTheme.gold, size: 24),
                              SizedBox(width: 8),
                              Text('مشاور ثبت‌کننده این فایل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person_outline, 'نام مشاور', property['agent_name'] ?? 'ثبت نشده'),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.phone_android, 'شماره تماس مشاور', property['agent_phone'] ?? 'ثبت نشده'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: property['status'] == 'available' && property['agent_phone'] != null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('شماره تماس مشاور: ${property['agent_phone']}'),
                                    backgroundColor: AppTheme.gold,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.phone, size: 24),
                        label: const Text('تماس با مشاور املاک', style: TextStyle(fontSize: 18)),
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
        Icon(icon, color: AppTheme.gold, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPrice ? AppTheme.textYellow : AppTheme.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
