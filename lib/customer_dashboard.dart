import 'package:flutter/material.dart';
import 'customer_search_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مشتری'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            _buildCard(context, Icons.search, 'جستجوی ملک', Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSearchScreen()));
            }),
            _buildCard(context, Icons.favorite, 'علاقه‌مندی‌ها', Colors.red, () {
              _showComingSoon(context, 'علاقه‌مندی‌ها');
            }),
            _buildCard(context, Icons.calendar_today, 'درخواست بازدید', Colors.green, () {
              _showComingSoon(context, 'درخواست بازدید');
            }),
            _buildCard(context, Icons.description, 'قراردادهای من', Colors.purple, () {
              _showComingSoon(context, 'قراردادهای من');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بخش $feature در نسخه‌های بعدی فعال می‌شود')),
    );
  }
}
