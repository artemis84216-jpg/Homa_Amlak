import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('درباره ما'),
        backgroundColor: Colors.cyan[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work, size: 80, color: Colors.cyan[700]),
                const SizedBox(height: 24),
                const Text('نرم‌افزار مدیریت املاک هما', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('نسخه ۱.۰.۰', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                const Text('این نرم‌افزار جهت مدیریت یکپارچه املاک، مشاوران، قراردادها و گزارشات مالی طراحی شده است.', textAlign: TextAlign.center, style: TextStyle(height: 1.6)),
                const SizedBox(height: 32),
                Text('طراحی و توسعه توسط: حسین', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
