import 'package:flutter/material.dart';
import 'app_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('درباره ما'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.gold, width: 2),
                  ),
                  child: const Icon(Icons.home_work, size: 60, color: AppTheme.gold),
                ),
                const SizedBox(height: 24),
                const Text('نرم‌افزار مدیریت املاک هما', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                const SizedBox(height: 8),
                const Text('Homa_Amlak', style: TextStyle(fontSize: 18, color: AppTheme.textYellow, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textGrey)),
                const SizedBox(height: 32),
                const Text(
                  'این نرم‌افزار جهت مدیریت یکپارچه املاک، مشاوران، قراردادها و گزارشات مالی طراحی شده است.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textWhite, height: 1.6),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.developer_mode, color: AppTheme.gold, size: 32),
                      const SizedBox(height: 8),
                      const Text('توسعه‌دهنده:', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('گروه نرم‌افزاری هما', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Homa_Software_Group', style: TextStyle(color: AppTheme.textYellow, fontSize: 14, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
