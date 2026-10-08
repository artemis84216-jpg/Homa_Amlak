import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class CustomerViewingsScreen extends StatefulWidget {
  const CustomerViewingsScreen({super.key});

  @override
  State<CustomerViewingsScreen> createState() => _CustomerViewingsScreenState();
}

class _CustomerViewingsScreenState extends State<CustomerViewingsScreen> {
  List<Map<String, dynamic>> _viewings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewings();
  }

  Future<void> _loadViewings() async {
    setState(() => _isLoading = true);
    // در این نسخه نمایشی، تمام بازدیدها را نشان می‌دهیم. 
    // در نسخه نهایی با لاگین مشتری، فقط بازدیدهای همان شماره تلفن فیلتر می‌شود.
    final data = await DatabaseHelper.instance.getAllViewings();
    setState(() {
      _viewings = data;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved': return 'تایید شده توسط مشاور ✅';
      case 'rejected': return 'رد شده توسط مشاور ❌';
      default: return 'در انتظار تایید مشاور ⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('بازدیدهای من'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadViewings)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _viewings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز درخواست بازدیدی ثبت نکرده‌اید', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _viewings.length,
                  itemBuilder: (context, index) {
                    final v = _viewings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(v['status']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getStatusColor(v['status'])),
                                    ),
                                    child: Text(
                                      _getStatusText(v['status']),
                                      style: TextStyle(color: _getStatusColor(v['status']), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                v['property_title'] ?? 'ملک نامشخص',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: AppTheme.gold),
                                  const SizedBox(width: 8),
                                  Text('تاریخ: ${v['viewing_date']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: AppTheme.gold),
                                  const SizedBox(width: 8),
                                  Text('ساعت: ${v['viewing_time']}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16)),
                                ],
                              ),
                              if (v['status'] == 'approved') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'بازدید شما تایید شد. لطفاً در زمان مقرر حاضر شوید.',
                                          style: TextStyle(color: Colors.green, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
