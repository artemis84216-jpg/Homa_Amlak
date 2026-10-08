import 'package:flutter/material.dart';
import 'agents_management_screen.dart';
import 'admin_properties_screen.dart';
import 'reports_screen.dart';
import 'contracts_screen.dart';
import 'expenses_screen.dart';
import 'about_screen.dart';       // جدید
import 'settings_screen.dart';    // جدید
import 'backup_screen.dart';      // جدید

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت'),
        backgroundColor: Colors.red[700],
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
            _buildCard(context, Icons.people, 'مشاوران', Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentsManagementScreen()));
            }),
            _buildCard(context, Icons.home, 'املاک', Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPropertiesScreen()));
            }),
            _buildCard(context, Icons.description, 'قراردادها', Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContractsScreen()));
            }),
            _buildCard(context, Icons.receipt_long, 'هزینه‌ها', Colors.red, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
            }),
            _buildCard(context, Icons.bar_chart, 'گزارشات', Colors.teal, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
            _buildCard(context, Icons.settings, 'تنظیمات', Colors.grey, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _buildCard(context, Icons.backup, 'پشتیبان', Colors.indigo, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
            }),
            _buildCard(context, Icons.info, 'درباره ما', Colors.cyan, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
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
}
