import 'package:flutter/material.dart';
import 'properties_list_screen.dart';
import 'add_property_screen.dart';

class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مشاور'),
        backgroundColor: Colors.green[700],
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
          _buildCard(context, Icons.add_home, 'ثبت ملک', Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
          }),
          _buildCard(context, Icons.home, 'املاک من', Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertiesListScreen()));
          }),
          _buildCard(context, Icons.people, 'مشتریان', Colors.orange, () {
            _showComingSoon(context, 'مشتریان');
          }),
          _buildCard(context, Icons.calendar_today, 'بازدیدها', Colors.purple, () {
            _showComingSoon(context, 'بازدیدها');
          }),
          _buildCard(context, Icons.description, 'قراردادها', Colors.teal, () {
            _showComingSoon(context, 'قراردادها');
          }),
          _buildCard(context, Icons.attach_money, 'کمیسیون', Colors.amber, () {
            _showComingSoon(context, 'کمیسیون');
          }),
        ],
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
      SnackBar(content: Text('بخش $feature به زودی اضافه می‌شود')),
    );
  }
}
