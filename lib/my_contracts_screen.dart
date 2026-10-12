import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllContracts();
    setState(() {
      _contracts = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('قراردادهای من'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadContracts)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _contracts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز قراردادی ثبت نشده است', style: TextStyle(fontSize: 16, color: AppTheme.textGrey)),
                      const SizedBox(height: 8),
                      Text('قراردادهای شما پس از ثبت توسط مدیر املاک در اینجا نمایش داده می‌شوند', style: TextStyle(fontSize: 13, color: AppTheme.textGrey, height: 1.5)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _contracts.length,
                  itemBuilder: (context, index) {
                    final c = _contracts[index];
                    final isSale = c['deal_type'] == 'sale';
                    
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
                                      color: (isSale ? Colors.green : Colors.blue).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isSale ? Colors.green : Colors.blue),
                                    ),
                                    child: Text(
                                      isSale ? 'فروش' : 'اجاره',
                                      style: TextStyle(color: isSale ? Colors.green : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: const Text(
                                      'فعال',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                c['property_title'] ?? 'ملک نامشخص',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.badge, 'مشاور', c['agent_name'] ?? 'نامشخص'),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.attach_money, 'مبلغ قرارداد', '${formatPrice(c['amount'])} تومان', isPrice: true),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.person, 'نام مشتری', c['customer_name'] ?? 'نامشخص'),
                              const SizedBox(height: 6),
                              _buildInfoRow(Icons.phone, 'شماره تماس', c['customer_phone'] ?? 'نامشخص'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.gold, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppTheme.textGrey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isPrice ? AppTheme.textYellow : AppTheme.textWhite,
              fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
