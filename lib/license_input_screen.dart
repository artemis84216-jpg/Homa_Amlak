import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'app_utils.dart';

class LicenseInputScreen extends StatefulWidget {
  const LicenseInputScreen({super.key});

  @override
  State<LicenseInputScreen> createState() => _LicenseInputScreenState();
}

class _LicenseInputScreenState extends State<LicenseInputScreen> {
  final _licenseController = TextEditingController();
  bool _isLoading = false;
  String _deviceId = 'در حال دریافت...';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    setState(() => _deviceId = id);
  }

  Future<void> _activateLicense() async {
    if (_licenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً کد لایسنس را وارد کنید'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = LicenseHelper.validateLicense(_licenseController.text.trim(), _deviceId);

    if (result == null || result.containsKey('error')) {
      setState(() => _isLoading = false);
      String errorMsg = 'کد لایسنس نامعتبر است';
      if (result != null) {
        switch (result['error']) {
          case 'device_mismatch': errorMsg = 'این کد لایسنس برای دستگاه دیگری صادر شده است'; break;
          case 'invalid_checksum': errorMsg = 'کد لایسنس دستکاری شده است'; break;
          case 'expired': errorMsg = 'کد لایسنس منقضی شده است'; break;
          case 'invalid_format': errorMsg = 'فرمت کد لایسنس نامعتبر است'; break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      return;
    }

    // دریافت اطلاعات پلن
    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == result['planId'], orElse: () => {});

    if (plan.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پلن مربوطه یافت نشد'), backgroundColor: Colors.red));
      return;
    }

    // ذخیره لایسنس
    await LicenseHelper.saveLicense(
      _licenseController.text.trim(),
      result['planId'],
      result['expiryDate'],
    );

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ لایسنس با موفقیت فعال شد - پلن: ${plan['name']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فعال‌سازی لایسنس'), centerTitle: true),
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
                  color: AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.info, color: AppTheme.gold), SizedBox(width: 8), Text('راهنمای فعال‌سازی', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 12),
                    const Text('۱. شناسه دستگاه زیر را کپی کنید', style: TextStyle(color: AppTheme.textWhite)),
                    const SizedBox(height: 8),
                    SelectableText(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 12),
                    const Text('۲. شناسه را برای توسعه‌دهنده ارسال کنید', style: TextStyle(color: AppTheme.textWhite)),
                    const SizedBox(height: 8),
                    const Text('۳. کد لایسنس دریافتی را در کادر زیر وارد کنید', style: TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _licenseController,
                style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 12),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'کد لایسنس',
                  hintText: 'کد دریافتی از توسعه‌دهنده را اینجا وارد کنید',
                  prefixIcon: Icon(Icons.key, color: AppTheme.gold),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _activateLicense,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                  label: Text(_isLoading ? 'در حال بررسی...' : 'فعال‌سازی لایسنس', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
