import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ViewingsListScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  const ViewingsListScreen({super.key, required this.agentData});

  @override
  State<ViewingsListScreen> createState() => _ViewingsListScreenState();
}

class _ViewingsListScreenState extends State<ViewingsListScreen> {
  List<Map<String, dynamic>> _viewings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewings();
  }

  Future<void> _loadViewings() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getViewingsByAgent(widget.agentData['name'] ?? '');
    setState(() {
      _viewings = data;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    await DatabaseHelper.instance.updateViewingStatus(id, status);
    _loadViewings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == 'approved' ? '✓ بازدید تایید شد' : (status == 'rejected' ? '✗ بازدید رد شد' : '✓ وضعیت به انتظار تغییر کرد')),
        backgroundColor: AppTheme.gold,
      ),
    );
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
      case 'approved': return 'تایید شده';
      case 'rejected': return 'رد شده';
      default: return 'در انتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('درخواست‌های بازدید'),
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
                      Text('هنوز درخواست بازدیدی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
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
                                  const Spacer(),
                                  const Icon(Icons.event, color: AppTheme.gold, size: 20),
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
                                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.textGrey),
                                  const SizedBox(width: 6),
                                  Text('تاریخ: ${v['viewing_date']}', style: const TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: AppTheme.textGrey),
                                  const SizedBox(width: 6),
                                  Text('ساعت: ${v['viewing_time']}', style: const TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
                                  const SizedBox(width: 6),
                                  Text('مشتری: ${v['customer_name']}', style: const TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: AppTheme.textGrey),
                                  const SizedBox(width: 6),
                                  Text('تلفن: ${v['customer_phone']}', style: const TextStyle(color: AppTheme.textWhite)),
                                ],
                              ),
                              if (v['notes'] != null && v['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.notes, size: 16, color: AppTheme.textGrey),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('توضیحات: ${v['notes']}', style: const TextStyle(color: AppTheme.textGrey))),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (v['status'] != 'approved')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(v['id'], 'approved'),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('تایید', style: TextStyle(fontSize: 14)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      ),
                                    ),
                                  if (v['status'] != 'approved' && v['status'] != 'rejected')
                                    const SizedBox(width: 8),
                                  if (v['status'] != 'rejected')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _updateStatus(v['id'], 'rejected'),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('رد', style: TextStyle(fontSize: 14)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
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
