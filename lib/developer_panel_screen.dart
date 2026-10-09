import 'package:flutter/material.dart';
import 'device_info_helper.dart';
import 'plans_management_screen.dart';
import 'app_utils.dart';

class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  bool _isLoading = true;
  Map<String, String> _deviceInfo = {};
  final _passwordController = TextEditingController();
  bool _isAuthenticated = false;
  final String _developerPassword = '2026'; // رمز پنل توسعه‌دهنده

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoHelper.instance.getFullDeviceInfo();
    setState(() {
      _deviceInfo = info;
      _isLoading = false;
    });
  }

  void _checkPassword() {
    if (_passwordController.text.trim() == _developerPassword) {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور اشتباه است'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل توسعه‌دهنده'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // هدر
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.gold.withOpacity(0.3), AppTheme.gold.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold, width: 2),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.developer_mode, color: AppTheme.gold, size: 50),
                          SizedBox(height: 8),
                          Text('پنل مدیریت توسعه‌دهنده', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                          SizedBox(height: 4),
                          Text('نسخه ۱.۰.۰ | Homa_Amlak', style: TextStyle(color: AppTheme.textYellow, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // بخش شناسه دستگاه
                    const Text('شناسه یکتای دستگاه مدیر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fingerprint, color: AppTheme.gold, size: 24),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Device ID:', style: TextStyle(color: AppTheme.textGrey, fontSize: 14))),
                              IconButton(
                                icon: const Icon(Icons.copy, color: AppTheme.gold, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('شناسه: ${_deviceInfo['deviceId']}')),
                                  );
                                },
                                tooltip: 'کپی شناسه',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _deviceInfo['deviceId'] ?? 'نامشخص',
                            style: const TextStyle(color: AppTheme.textYellow, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                          const Divider(color: AppTheme.gold, height: 24),
                          Text('برند: ${_deviceInfo['brand']}', style: const TextStyle(color: AppTheme.textWhite)),
                          const SizedBox(height: 4),
                          Text('مدل: ${_deviceInfo['model']}', style: const TextStyle(color: AppTheme.textWhite)),
                          const SizedBox(height: 4),
                          Text('اندروید: ${_deviceInfo['androidVersion']}', style: const TextStyle(color: AppTheme.textWhite)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ این شناسه را برای توسعه‌دهنده ارسال کنید تا کد لایسنس برایتان صادر شود.',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // بخش ورود به مدیریت پلن‌ها با رمز
                    if (!_isAuthenticated) ...[
                      const Text('ورود به مدیریت پلن‌های اشتراک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(
                          labelText: 'رمز عبور توسعه‌دهنده',
                          prefixIcon: Icon(Icons.lock, color: AppTheme.gold),
                          hintText: 'رمز را وارد کنید',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _checkPassword,
                        icon: const Icon(Icons.login),
                        label: const Text('ورود به پنل پلن‌ها'),
                      ),
                    ] else ...[
                      const Text('پلن‌های اشتراک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansManagementScreen()));
                        },
                        icon: const Icon(Icons.subscriptions),
                        label: const Text('مدیریت پلن‌های اشتراک'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
