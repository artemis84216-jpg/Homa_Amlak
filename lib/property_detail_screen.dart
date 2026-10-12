import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_utils.dart';
import 'property_image_gallery.dart';
import 'request_viewing_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_property_ids') ?? [];
    setState(() => _isFavorite = favIds.contains(widget.property['id'].toString()));
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorite_property_ids') ?? [];
    final idStr = widget.property['id'].toString();
    
    if (_isFavorite) {
      favIds.remove(idStr);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ از علاقه‌مندی‌ها حذف شد'), backgroundColor: AppTheme.gold),
      );
    } else {
      favIds.add(idStr);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ به علاقه‌مندی‌ها اضافه شد'), backgroundColor: Colors.green),
      );
    }
    
    await prefs.setStringList('favorite_property_ids', favIds);
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('جزئیات ملک'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppTheme.gold,
              size: 28,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PropertyImageGallery(imagesJson: widget.property['images']),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.property['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.home_work, color: AppTheme.gold, size: 20),
                        const SizedBox(width: 4),
                        Text(widget.property['type'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textYellow)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.property['status'] == 'available' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: widget.property['status'] == 'available' ? Colors.green : Colors.grey),
                          ),
                          child: Text(
                            widget.property['status'] == 'available' ? 'موجود' : 'فروخته شده',
                            style: TextStyle(
                              color: widget.property['status'] == 'available' ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppTheme.gold),
                    _buildInfoRow(Icons.square_foot, 'متراژ', '${formatNumber((widget.property['area'] ?? 0).toInt())} متر مربع'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.attach_money, 'قیمت', '${formatPrice(widget.property['price'])} تومان', isPrice: true),
                    if (widget.property['listing_type'] == 'rent' && widget.property['monthly_rent'] != null && (widget.property['monthly_rent'] as num) > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.money, 'اجاره ماهیانه', '${formatPrice(widget.property['monthly_rent'])} تومان', isPrice: true),
                    ],
                    if ((widget.property['bedrooms'] ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.bed, 'تعداد خواب', formatNumber(widget.property['bedrooms'].toInt())),
                    ],
                    if ((widget.property['floor'] ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.layers, 'طبقه', '${formatNumber(widget.property['floor'].toInt())} از ${formatNumber((widget.property['total_floors'] ?? 0).toInt())}'),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'آدرس', widget.property['address'] ?? 'بدون آدرس'),
                    const Divider(height: 32, color: AppTheme.gold),
                    const Text('مشخصات مالک', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.person, 'نام مالک', widget.property['owner_name'] ?? 'ثبت نشده'),
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
                          _buildInfoRow(Icons.person_outline, 'نام مشاور', widget.property['agent_name'] ?? 'ثبت نشده'),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.phone_android, 'شماره تماس مشاور', widget.property['agent_phone'] ?? 'ثبت نشده'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: widget.property['status'] == 'available' && widget.property['agent_phone'] != null
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('شماره تماس مشاور: ${widget.property['agent_phone']}'), backgroundColor: AppTheme.gold),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.phone, size: 24),
                        label: const Text('تماس با مشاور املاک', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: widget.property['status'] == 'available'
                            ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RequestViewingScreen(property: widget.property)),
                                );
                                if (result == true) {
                                  Navigator.pop(context);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.event, size: 24, color: AppTheme.gold),
                        label: const Text('درخواست بازدید', style: TextStyle(fontSize: 18, color: AppTheme.gold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.gold, width: 2),
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
