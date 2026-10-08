import 'package:flutter/material.dart';
import 'customer_search_screen.dart';
import 'customer_viewings_screen.dart'; // <-- اضافه شد
import 'app_utils.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل مشتری'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.gold),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, Icons.search, 'جستجوی ملک', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchScreen()));
            }),
            _buildCard(context, Icons.event, 'بازدیدهای من', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerViewingsScreen()));
            }),
            _buildCard(context, Icons.favorite, 'علاقه‌مندی‌ها', AppTheme.gold, () {
              _showComingSoon(context, 'علاقه‌مندی‌ها');
            }),
            _buildCard(context, Icons.description, 'قراردادهای من', AppTheme.gold, () {
              _showComingSoon(context, 'قراردادهای من');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بخش $feature به زودی اضافه می‌شود'), backgroundColor: AppTheme.gold),
    );
  }
}
