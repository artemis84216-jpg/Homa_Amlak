import 'package:flutter/material.dart';
import 'database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  int _totalProperties = 0;
  int _soldProperties = 0;
  int _availableProperties = 0;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  int _totalAgents = 0;
  int _activeAgents = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final properties = await db.query('properties');
    _totalProperties = properties.length;
    _soldProperties = properties.where((p) => p['status'] == 'sold').length;
    _availableProperties = properties.where((p) => p['status'] == 'available').length;

    final contracts = await db.query('contracts');
    // اصلاح خطای نوع داده در اینجا:
    _totalIncome = contracts.fold(0.0, (sum, c) => sum + ((c['amount'] as num?)?.toDouble() ?? 0.0));

    final expenses = await db.query('expenses');
    // اصلاح خطای نوع داده در اینجا:
    _totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    final agents = await db.query('agents');
    _totalAgents = agents.length;
    _activeAgents = agents.where((a) => a['status'] == 'active').length;

    setState(() => _isLoading = false);
  }

  String _formatNumber(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات مالی'),
        backgroundColor: Colors.teal[700],
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.home, color: Colors.blue[700], size: 28),
                                const SizedBox(width: 8),
                                const Text('آمار املاک', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildStatRow('کل املاک', _totalProperties.toString(), Colors.blue),
                            _buildStatRow('املاک موجود', _availableProperties.toString(), Colors.green),
                            _buildStatRow('املاک فروخته شده', _soldProperties.toString(), Colors.red),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green[700], size: 28),
                                const SizedBox(width: 8),
                                const Text('آمار مالی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildStatRow('کل درآمد', '${_formatNumber(_totalIncome.toInt())} تومان', Colors.green),
                            _buildStatRow('کل هزینه', '${_formatNumber(_totalExpenses.toInt())} تومان', Colors.red),
                            const Divider(height: 16),
                            _buildStatRow(
                              'سود خالص',
                              '${_formatNumber((_totalIncome - _totalExpenses).toInt())} تومان',
                              _totalIncome - _totalExpenses >= 0 ? Colors.green : Colors.red,
                              isLarge: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: Colors.purple[700], size: 28),
                                const SizedBox(width: 8),
                                const Text('آمار مشاوران', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildStatRow('کل مشاوران', _totalAgents.toString(), Colors.purple),
                            _buildStatRow('مشاوران فعال', _activeAgents.toString(), Colors.green),
                            _buildStatRow('مشاوران غیرفعال', (_totalAgents - _activeAgents).toString(), Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 18 : 16, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
