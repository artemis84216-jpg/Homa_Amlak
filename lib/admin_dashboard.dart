import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیر'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(Icons.people, 'مشاوران', Colors.blue),
          _buildCard(Icons.home, 'املاک', Colors.green),
          _buildCard(Icons.description, 'قراردادها', Colors.orange),
          _buildCard(Icons.payment, 'پرداخت‌ها', Colors.purple),
          _buildCard(Icons.receipt_long, 'هزینه‌ها', Colors.red),
          _buildCard(Icons.bar_chart, 'گزارشات', Colors.teal),
          _buildCard(Icons.settings, 'تنظیمات', Colors.grey),
          _buildCard(Icons.backup, 'پشتیبان', Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
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
}
