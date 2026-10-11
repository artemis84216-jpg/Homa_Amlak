import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('expenses', orderBy: 'id DESC');
    setState(() {
      _expenses = data;
      _isLoading = false;
    });
  }

  Future<void> _showAddExpenseDialog() async {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final categories = ['قبوض', 'حقوق', 'تبلیغات', 'تعمیرات', 'سایر'];
    String selectedCategory = categories.first;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: const Text('ثبت هزینه جدید', style: TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: AppTheme.cardBlack,
                    decoration: const InputDecoration(labelText: 'دسته‌بندی', prefixIcon: Icon(Icons.category, color: AppTheme.gold)),
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CommaSeparatorFormatter()],
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'مبلغ (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)', prefixIcon: Icon(Icons.notes, color: AppTheme.gold)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ الزامی است')));
                    return;
                  }

                  final db = await DatabaseHelper.instance.database;
                  await db.insert('expenses', {
                    'category': selectedCategory,
                    'amount': double.parse(toEnglishDigits(amountController.text.replaceAll(',', ''))),
                    'description': descriptionController.text.trim(),
                    'date': DateTime.now().toIso8601String(),
                  });

                  Navigator.pop(ctx);
                  _loadExpenses();
                },
                child: const Text('ثبت'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا از حذف این هزینه مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('مدیریت هزینه‌ها'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadExpenses)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      Text('هنوز هزینه‌ای ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          child: const Icon(Icons.receipt, color: Colors.red),
                        ),
                        title: Text(expense['category'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          expense['description']?.toString().isNotEmpty == true 
                              ? expense['description'] 
                              : 'بدون توضیحات',
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${formatPrice(expense['amount'])} تومان', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteExpense(expense['id']),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ثبت هزینه جدید'),
      ),
    );
  }
}

class CommaSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = toEnglishDigits(newValue.text.replaceAll(',', ''));
    if (cleanText.isEmpty) return newValue;
    final intVal = int.tryParse(cleanText);
    if (intVal == null) return oldValue;
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
