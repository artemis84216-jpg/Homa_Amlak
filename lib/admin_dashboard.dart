import 'package:flutter/material.dart';
import 'agents_management_screen.dart';
import 'admin_properties_screen.dart';
import 'reports_screen.dart';
import 'admin_deal_registration_screen.dart'; // <-- اضافه شد
import 'expenses_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'app_utils.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل مدیریت'),
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
            _buildCard(context, Icons.people, 'مشاوران', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentsManagementScreen()));
            }),
            _buildCard(context, Icons.home, 'املاک', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPropertiesScreen()));
            }),
            _buildCard(context, Icons.description, 'قراردادها', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDealRegistrationScreen()));
            }),
            _buildCard(context, Icons.receipt_long, 'هزینه‌ها', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
            }),
            _buildCard(context, Icons.bar_chart, 'گزارشات', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
            _buildCard(context, Icons.settings, 'تنظیمات', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _buildCard(context, Icons.backup, 'پشتیبان', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
            }),
            _buildCard(context, Icons.info, 'درباره ما', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
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
}
