import 'package:flutter/material.dart';
import 'dart:io';
import 'properties_list_screen.dart';
import 'add_property_screen.dart';
import 'app_utils.dart';

class AgentDashboard extends StatelessWidget {
  final Map<String, dynamic> agentData;
  const AgentDashboard({super.key, required this.agentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (agentData['profile_image'] != null)
              CircleAvatar(
                radius: 16, 
                backgroundImage: FileImage(File(agentData['profile_image'])),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                agentData['name'] ?? 'پنل مشاور', 
                style: const TextStyle(fontSize: 16, color: AppTheme.gold), 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, Icons.add_home, 'ثبت ملک', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen(currentAgent: agentData)));
            }),
            _buildCard(context, Icons.home, 'املاک من', AppTheme.gold, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PropertiesListScreen(agentId: agentData['id'])));
            }),
            _buildCard(context, Icons.people, 'مشتریان', AppTheme.gold, () { _showComingSoon(context, 'مشتریان'); }),
            _buildCard(context, Icons.calendar_today, 'بازدیدها', AppTheme.gold, () { _showComingSoon(context, 'بازدیدها'); }),
            _buildCard(context, Icons.attach_money, 'کمیسیون من', AppTheme.gold, () { _showComingSoon(context, 'کمیسیون'); }),
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
