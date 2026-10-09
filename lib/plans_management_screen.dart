import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class PlansManagementScreen extends StatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  State<PlansManagementScreen> createState() => _PlansManagementScreenState();
}

class _PlansManagementScreenState extends State<PlansManagementScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllPlans();
    setState(() {
      _plans = data;
      _isLoading = false;
    });
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final nameController = TextEditingController(text: plan?['name']?.toString() ?? '');
    final durationValueController = TextEditingController(text: plan?['duration_months']?.toString() ?? '');
    final priceController = TextEditingController(text: plan?['price']?.toString() ?? '');
    final maxAgentsController = TextEditingController(text: plan?['max_agents']?.toString() ?? '');
    final maxPropertiesController = TextEditingController(text: plan?['max_properties']?.toString() ?? '');
    
    String durationType = 'months'; // months یا days
    bool unlimitedAgents = (plan?['max_agents'] ?? 0) == 0;
    bool unlimitedProperties = (plan?['max_properties'] ?? 0) == 0;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش پلن' : 'افزودن پلن جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام پلن (مثلاً: طلایی، نقره‌ای)', prefixIcon: Icon(Icons.label, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: durationValueController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مدت زمان', prefixIcon: Icon(Icons.calendar_today, color: AppTheme.gold))),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: durationType,
                        dropdownColor: AppTheme.cardBlack,
                        style: const TextStyle(color: AppTheme.textWhite),
                        items: const [
                          DropdownMenuItem(value: 'days', child: Text('روز')),
                          DropdownMenuItem(value: 'months', child: Text('ماه')),
                        ],
                        onChanged: (v) => setStateDialog(() => durationType = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت (تومان) - 0 برای رایگان', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('مشاوران نامحدود', style: TextStyle(color: AppTheme.textWhite)),
                    value: unlimitedAgents,
                    activeColor: AppTheme.gold,
                    onChanged: (v) {
                      setStateDialog(() {
                        unlimitedAgents = v ?? false;
                        if (unlimitedAgents) maxAgentsController.text = '0';
                      });
                    },
                  ),
                  if (!unlimitedAgents)
                    TextField(controller: maxAgentsController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سقف تعداد مشاوران', prefixIcon: Icon(Icons.people, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('فایل ملک نامحدود', style: TextStyle(color: AppTheme.textWhite)),
                    value: unlimitedProperties,
                    activeColor: AppTheme.gold,
                    onChanged: (v) {
                      setStateDialog(() {
                        unlimitedProperties = v ?? false;
                        if (unlimitedProperties) maxPropertiesController.text = '0';
                      });
                    },
                  ),
                  if (!unlimitedProperties)
                    TextField(controller: maxPropertiesController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سقف تعداد فایل ملک', prefixIcon: Icon(Icons.home, color: AppTheme.gold))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || durationValueController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و مدت زمان الزامی است')));
                    return;
                  }
                  
                  int durationMonths = int.tryParse(toEnglishDigits(durationValueController.text)) ?? 0;
                  if (durationType == 'days') {
                    // تبدیل روز به کسر ماه (برای نمایش)
                    durationMonths = durationMonths; // همان عدد روز را ذخیره می‌کنیم اما نوع را در نام ذخیره می‌کنیم
                  }
                  
                  final planData = {
                    'name': '${nameController.text.trim()}${durationType == 'days' ? ' (روز)' : ''}',
                    'duration_months': durationMonths,
                    'duration_type': durationType,
                    'price': double.tryParse(toEnglishDigits(priceController.text)) ?? 0,
                    'max_agents': unlimitedAgents ? 0 : (int.tryParse(toEnglishDigits(maxAgentsController.text)) ?? 0),
                    'max_properties': unlimitedProperties ? 0 : (int.tryParse(toEnglishDigits(maxPropertiesController.text)) ?? 0),
                    'is_active': 1,
                  };
                  
                  if (isEdit) {
                    await DatabaseHelper.instance.updatePlan(plan!['id'], planData);
                  } else {
                    await DatabaseHelper.instance.insertPlan(planData);
                  }
                  Navigator.pop(ctx);
                  _loadPlans();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا از حذف این پلن مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deletePlan(id);
      _loadPlans();
    }
  }

  String _getDurationText(Map<String, dynamic> plan) {
    final duration = plan['duration_months'];
    final type = plan['duration_type'] ?? plan['name'].toString().contains('(روز)') ? 'days' : 'months';
    final durationStr = toPersianDigits(duration.toString());
    
    if (type == 'days') {
      return '$durationStr روزه';
    } else {
      switch (duration) {
        case 1: return 'ماهانه';
        case 3: return '۳ ماهه';
        case 6: return '۶ ماهه';
        case 12: return 'یکساله';
        default: return '$durationStr ماهه';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت پلن‌ها'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subscriptions, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز پلنی تعریف نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final plan = _plans[index];
                    final isUnlimitedAgents = (plan['max_agents'] ?? 0) == 0;
                    final isUnlimitedProperties = (plan['max_properties'] ?? 0) == 0;
                    
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
                                      color: AppTheme.gold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.gold),
                                    ),
                                    child: Text(
                                      _getDurationText(plan),
                                      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(plan['name']?.toString().replaceAll(' (روز)', '') ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.attach_money, size: 16, color: AppTheme.textGrey),
                                const SizedBox(width: 4),
                                Text((plan['price'] ?? 0) == 0 ? 'رایگان' : '${formatPrice(plan['price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold)),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                const Icon(Icons.people, size: 16, color: AppTheme.textGrey),
                                const SizedBox(width: 4),
                                Text('مشاوران: ${isUnlimitedAgents ? "نامحدود" : formatNumber(plan['max_agents'].toInt())}', style: const TextStyle(color: AppTheme.textWhite)),
                                const SizedBox(width: 16),
                                const Icon(Icons.home, size: 16, color: AppTheme.textGrey),
                                const SizedBox(width: 4),
                                Text('ملک: ${isUnlimitedProperties ? "نامحدود" : formatNumber(plan['max_properties'].toInt())}', style: const TextStyle(color: AppTheme.textWhite)),
                              ]),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showPlanDialog(plan: plan),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('ویرایش', style: TextStyle(fontSize: 14)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _deletePlan(plan['id']),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('حذف', style: TextStyle(fontSize: 14)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('افزودن پلن'),
      ),
    );
  }
}
