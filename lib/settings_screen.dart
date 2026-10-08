import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: Colors.grey[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('اعلان‌ها (Notifications)'),
                subtitle: const Text('دریافت اعلان برای قراردادهای جدید'),
                value: _notifications,
                onChanged: (val) => setState(() => _notifications = val),
                secondary: const Icon(Icons.notifications),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('حالت شب (Dark Mode)'),
                subtitle: const Text('تغییر تم برنامه به رنگ تیره'),
                value: _darkMode,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('این ویژگی در نسخه‌های بعدی فعال می‌شود')),
                  );
                },
                secondary: const Icon(Icons.dark_mode),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('تغییر رمز عبور'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('فرم تغییر رمز به زودی اضافه می‌شود')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
