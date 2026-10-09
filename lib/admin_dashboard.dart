import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'agents_management_screen.dart';
import 'admin_properties_screen.dart';
import 'reports_screen.dart';
import 'admin_deal_registration_screen.dart';
import 'expenses_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'license_input_screen.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _deviceId = 'در حال دریافت...';
  Map<String, dynamic>? _license;
  String _planName = 'بدون لایسنس';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    final license = await LicenseHelper.getLicense();
    
    String planName = 'بدون لایسنس';
    if (license != null && license['isActive'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
      if (plan.isNotEmpty) planName = plan['name'] ?? 'پلن نامشخص';
    }

    setState(() {
      _deviceId = id;
      _license = license;
      _planName = planName;
      _isLoading = false;
    });

    // نمایش هشدار ۲ روز قبل از انقضا
    if (license != null && license['isActive'] == true) {
      final daysRemaining = license['daysRemaining'];
      if (daysRemaining <= 2 && daysRemaining >= 0) {
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ لایسنس شما ${toPersianDigits(daysRemaining.toString())} روز دیگر منقضی می‌شود. برای تمدید با توسعه‌دهنده تماس بگیرید.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }
      }
    }
  }

  bool get _isLicenseActive => _license != null && _license!['isActive'] == true;

  Color _getLicenseColor() {
    if (!_isLicenseActive) return Colors.red;
    final days = _license!['daysRemaining'];
    if (days <= 2) return Colors.orange;
    return Colors.green;
  }

  String _getLicenseStatus() {
    if (!_isLicenseActive) return 'غیرفعال - برای استفاده از اپ لایسنس تهیه کنید';
    final days = _license!['daysRemaining'];
    final expiryJalali = _license!['expiryJalali'];
    return '${toPersianDigits(days.toString())} روز باقی‌مانده | انقضا: ${toPersianDigits(expiryJalali.year.toString())}/${toPersianDigits(expiryJalali.month.toString().padLeft(2, '0'))}/${toPersianDigits(expiryJalali.day.toString().padLeft(2, '0'))}';
  }

  void _showLicenseRequired(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('دسترسی محدود', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('برای استفاده از بخش "$feature" باید لایسنس فعال داشته باشید.', style: const TextStyle(color: AppTheme.textWhite)),
              const SizedBox(height: 12),
              const Text('لطفاً شناسه دستگاه خود را برای توسعه‌دهنده ارسال کنید تا کد لایسنس دریافت نمایید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseInputScreen()));
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.key, size: 18),
              label: const Text('فعال‌سازی لایسنس'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen, String feature) {
    if (!_isLicenseActive) {
      _showLicenseRequired(feature);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('پنل مدیریت'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.gold), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  // کارت وضعیت لایسنس
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getLicenseColor(), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: _getLicenseColor(), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('لایسنس: $_planName', style: TextStyle(color: _getLicenseColor(), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getLicenseColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_isLicenseActive ? 'فعال' : 'غیرفعال', style: TextStyle(color: _getLicenseColor(), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_getLicenseStatus(), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        if (!_isLicenseActive) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseInputScreen()));
                                if (result == true) _loadData();
                              },
                              icon: const Icon(Icons.key, size: 18),
                              label: const Text('فعال‌سازی لایسنس', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // کارت شناسه دستگاه
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gold, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint, color: AppTheme.gold, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('شناسه دستگاه شما:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.gold, size: 20),
                          tooltip: 'کپی شناسه',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _deviceId));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ شناسه دستگاه کپی شد'), backgroundColor: AppTheme.gold));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildCard(context, Icons.people, 'مشاوران', AppTheme.gold, () => _navigateTo(const AgentsManagementScreen(), 'مشاوران')),
                        _buildCard(context, Icons.home, 'املاک', AppTheme.gold, () => _navigateTo(const AdminPropertiesScreen(), 'املاک')),
                        _buildCard(context, Icons.description, 'قراردادها', AppTheme.gold, () => _navigateTo(const AdminDealRegistrationScreen(), 'قراردادها')),
                        _buildCard(context, Icons.receipt_long, 'هزینه‌ها', AppTheme.gold, () => _navigateTo(const ExpensesScreen(), 'هزینه‌ها')),
                        _buildCard(context, Icons.bar_chart, 'گزارشات', AppTheme.gold, () => _navigateTo(const ReportsScreen(), 'گزارشات')),
                        _buildCard(context, Icons.settings, 'تنظیمات', AppTheme.gold, () => _navigateTo(const SettingsScreen(), 'تنظیمات')),
                        _buildCard(context, Icons.backup, 'پشتیبان', AppTheme.gold, () => _navigateTo(const BackupScreen(), 'پشتیبان')),
                        _buildCard(context, Icons.info, 'درباره ما', AppTheme.gold, () => _navigateTo(const AboutScreen(), 'درباره ما')),
                      ],
                    ),
                  ),
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
            Icon(icon, size: 40, color: _isLicenseActive ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isLicenseActive ? AppTheme.textWhite : Colors.grey)),
            if (!_isLicenseActive) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock, size: 14, color: Colors.red),
            ],
          ],
        ),
      ),
    );
  }
}
