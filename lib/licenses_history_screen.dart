import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class LicensesHistoryScreen extends StatefulWidget {
  const LicensesHistoryScreen({super.key});

  @override
  State<LicensesHistoryScreen> createState() => _LicensesHistoryScreenState();
}

class _LicensesHistoryScreenState extends State<LicensesHistoryScreen> {
  List<Map<String, dynamic>> _licenses = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses({String? query}) async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> data;
    if (query != null && query.isNotEmpty) {
      data = await DatabaseHelper.instance.searchLicenses(query);
    } else {
      data = await DatabaseHelper.instance.getAllLicenses();
    }
    setState(() {
      _licenses = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteLicense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا از حذف این لایسنس از سوابق مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteLicense(id);
      _loadLicenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سوابق لایسنس‌ها'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'جستجو در نام املاک یا شناسه دستگاه...',
                  hintStyle: const TextStyle(color: AppTheme.textGrey),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.gold),
                          onPressed: () {
                            _searchController.clear();
                            _loadLicenses();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => _loadLicenses(query: value),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                  : _licenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: AppTheme.textGrey),
                              const SizedBox(height: 16),
                              Text('هنوز لایسنسی صادر نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _licenses.length,
                          itemBuilder: (context, index) {
                            final license = _licenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.business, color: AppTheme.gold, size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            license['estate_name'] ?? '',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteLicense(license['id']),
                                          tooltip: 'حذف از سوابق',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow('پلن', license['plan_name'] ?? ''),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('تاریخ انقضا', license['expiry_date'] ?? ''),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.fingerprint, color: AppTheme.textGrey, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('شناسه دستگاه:', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              SelectableText(
                                                license['device_id'] ?? '',
                                                style: const TextStyle(color: AppTheme.textWhite, fontSize: 11, fontFamily: 'monospace'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, color: AppTheme.gold, size: 18),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: license['device_id'] ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ شناسه کپی شد')));
                                          },
                                          tooltip: 'کپی شناسه',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.key, color: AppTheme.textGrey, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('کد لایسنس:', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              SelectableText(
                                                license['license_code'] ?? '',
                                                style: const TextStyle(color: AppTheme.textYellow, fontSize: 10, fontFamily: 'monospace'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, color: AppTheme.gold, size: 18),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: license['license_code'] ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ کد لایسنس کپی شد')));
                                          },
                                          tooltip: 'کپی کد',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Icon(Icons.label, color: AppTheme.textGrey, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppTheme.textGrey)),
        Text(value, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
