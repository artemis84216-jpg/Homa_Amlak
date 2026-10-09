import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'license_helper.dart';
import 'plans_management_screen.dart';
import 'app_utils.dart';

class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  final _passwordController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  Jalali? _expiryDate;
  String? _generatedLicense;
  final String _developerPassword = '2026';

  Future<void> _loadPlans() async {
    final data = await DatabaseHelper.instance.getAllPlans();
    setState(() => _plans = data);
  }

  void _checkPassword() {
    if (_passwordController.text.trim() == _developerPassword) {
      setState(() => _isAuthenticated = true);
      _loadPlans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور اشتباه است'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatJalali(Jalali? date) {
    if (date == null) return 'انتخاب تاریخ انقضا';
    return '${toPersianDigits(date.year.toString())}/${toPersianDigits(date.month.toString().padLeft(2, '0'))}/${toPersianDigits(date.day.toString().padLeft(2, '0'))}';
  }

  // محاسبه خودکار تاریخ انقضا بر اساس پلن
  void _calculateExpiryDate() {
    if (_selectedPlan == null) {
      setState(() => _expiryDate = null);
      return;
    }

    final durationValue = _selectedPlan!['duration_value'] ?? 0;
    final durationType = _selectedPlan!['duration_type'] ?? 'months';
    
    Jalali expiry;
    if (durationType == 'days') {
      expiry = Jalali.now().addDays(durationValue);
    } else {
      expiry = Jalali.now().addMonths(durationValue);
    }
    
    setState(() => _expiryDate = expiry);
  }

  Future<void> _generateLicense() async {
    if (_deviceIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شناسه دستگاه مدیر را وارد کنید'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('یک پلن انتخاب کنید'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاریخ انقضا را انتخاب کنید'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final license = LicenseHelper.generateLicense(
      deviceId: _deviceIdController.text.trim(),
      expiryDate: _expiryDate!,
      planId: _selectedPlan!['id'],
    );

    setState(() {
      _generatedLicense = license;
      _isLoading = false;
    });
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('⚠️ هشدار جدی', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'این عمل تمام اطلاعات دیتابیس مدیر (املاک، مشاوران، قراردادها و...) را پاک می‌کند. آیا مطمئن هستید؟',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بله، پاک کن', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.resetDatabase();
      await LicenseHelper.clearLicense();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ دیتابیس با موفقیت پاک شد'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('پنل توسعه‌دهنده'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.3), AppTheme.gold.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.developer_mode, color: AppTheme.gold, size: 50),
                    SizedBox(height: 8),
                    Text('پنل مدیریت توسعه‌دهنده', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold)),
                    SizedBox(height: 4),
                    Text('Homa_Amlak | نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textYellow, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!_isAuthenticated) ...[
                const Text('ورود به پنل توسعه‌دهنده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'رمز عبور توسعه‌دهنده', prefixIcon: Icon(Icons.lock, color: AppTheme.gold)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: _checkPassword, icon: const Icon(Icons.login), label: const Text('ورود')),
              ] else ...[
                const Text('۱. تولید کد لایسنس برای مدیر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _deviceIdController,
                  style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace'),
                  decoration: const InputDecoration(labelText: 'شناسه دستگاه مدیر (Device ID)', prefixIcon: Icon(Icons.fingerprint, color: AppTheme.gold), hintText: 'Device ID را اینجا وارد کنید'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedPlan,
                  dropdownColor: AppTheme.cardBlack,
                  decoration: const InputDecoration(labelText: 'انتخاب پلن', prefixIcon: Icon(Icons.subscriptions, color: AppTheme.gold)),
                  items: _plans.map((p) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: p,
                      child: Text(p['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedPlan = val);
                    _calculateExpiryDate(); // محاسبه خودکار تاریخ انقضا
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showPersianDatePicker(
                      context: context,
                      initialDate: _expiryDate ?? Jalali.now().addDays(30),
                      firstDate: Jalali.now(),
                      lastDate: Jalali(1450),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.gold,
                              onPrimary: Colors.black,
                              surface: AppTheme.cardBlack,
                              onSurface: AppTheme.textWhite,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _expiryDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                  label: Text(_formatJalali(_expiryDate), style: const TextStyle(color: AppTheme.textWhite)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
                ),
                const SizedBox(height: 8),
                if (_selectedPlan != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تاریخ انقضا به صورت خودکار بر اساس پلن "${_selectedPlan!['name']}" محاسبه شده است. می‌توانید آن را تغییر دهید.',
                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateLicense,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.key),
                  label: const Text('تولید کد لایسنس'),
                ),

                if (_generatedLicense != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('کد لایسنس تولید شد', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        SelectableText(
                          _generatedLicense!,
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedLicense!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ کد لایسنس کپی شد')));
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('کپی کد لایسنس'),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(color: AppTheme.gold, height: 40),

                const Text('۲. مدیریت پلن‌های اشتراک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansManagementScreen())),
                  icon: const Icon(Icons.settings),
                  label: const Text('مدیریت پلن‌ها'),
                ),

                const Divider(color: AppTheme.gold, height: 40),

                const Text('۳. ابزارهای توسعه‌دهنده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _resetDatabase,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('پاک کردن کامل دیتابیس مدیر'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ این قابلیت برای زمانی است که می‌خواهید اپلیکیشن را به یک املاک جدید بفروشید و نیاز دارید تمام اطلاعات مدیر قبلی پاک شود.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
