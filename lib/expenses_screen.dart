import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  
  String _selectedCategory = 'همه';
  String _searchQuery = '';
  Jalali? _startDate;
  Jalali? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await DatabaseHelper.instance.getExpenseCategories();
    final startStr = _startDate != null ? '${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}' : null;
    final endStr = _endDate != null ? '${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}' : null;
    
    final exps = await DatabaseHelper.instance.getExpenses(
      category: _selectedCategory == 'همه' ? null : _selectedCategory,
      startDate: startStr,
      endDate: endStr,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    
    setState(() {
      _categories = cats;
      _expenses = exps;
      _isLoading = false;
    });
  }

  Future<void> _showAddExpenseDialog() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _categories.isNotEmpty ? _categories.first['name'] : 'سایر';
    Jalali selectedDate = Jalali.now();

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
                    items: _categories.map((cat) => DropdownMenuItem(value: cat['name'], child: Text(cat['name']))).toList(),
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
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showPersianDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: Jalali(1390),
                        lastDate: Jalali(1450),
                        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.gold, onPrimary: Colors.black, surface: AppTheme.cardBlack, onSurface: AppTheme.textWhite)), child: child!),
                      );
                      if (picked != null) setStateDialog(() => selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                    label: Text('${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textWhite)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold)),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ الزامی است')));
                    return;
                  }
                  final dateStr = '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}';
                  await DatabaseHelper.instance.insertExpense({
                    'category': selectedCategory,
                    'amount': double.parse(toEnglishDigits(amountController.text.replaceAll(',', ''))),
                    'description': descriptionController.text.trim(),
                    'date': dateStr,
                  });
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('ثبت'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _manageCategories() async {
    final newCategoryController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('مدیریت دسته‌بندی‌ها', style: TextStyle(color: AppTheme.gold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: TextFormField(controller: newCategoryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام دسته‌بندی جدید', hintText: 'مثلاً: پذیرایی'))),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.add, color: AppTheme.gold), onPressed: () async {
                    if (newCategoryController.text.trim().isNotEmpty) {
                      await DatabaseHelper.instance.addExpenseCategory(newCategoryController.text.trim());
                      newCategoryController.clear();
                      _loadData(); // رفرش لیست
                    }
                  })
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return ListTile(
                      title: Text(cat['name'], style: const TextStyle(color: AppTheme.textWhite)),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        await DatabaseHelper.instance.deleteExpenseCategory(cat['id']);
                        _loadData();
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن', style: TextStyle(color: AppTheme.gold)))],
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
      await DatabaseHelper.instance.deleteExpense(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('مدیریت هزینه‌ها'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppTheme.gold), onPressed: _manageCategories, tooltip: 'مدیریت دسته‌بندی‌ها'),
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // بخش فیلتر و جستجو
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.cardBlack,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) { setState(() => _searchQuery = v); _loadData(); },
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'جستجو در توضیحات یا دسته‌بندی...',
                    hintStyle: const TextStyle(color: AppTheme.textGrey),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { setState(() => _searchQuery = ''); _loadData(); }) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: AppTheme.cardBlack,
                        decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: [const DropdownMenuItem(value: 'همه', child: Text('همه')), ..._categories.map((c) => DropdownMenuItem(value: c['name'], child: Text(c['name'])))],
                        onChanged: (v) { setState(() => _selectedCategory = v!); _loadData(); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showPersianDatePicker(context: context, initialDate: _startDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450));
                          if (picked != null) { setState(() => _startDate = picked); _loadData(); }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18, color: AppTheme.gold),
                        label: Text(_startDate != null ? '${_startDate!.month}/${_startDate!.day}' : 'از تاریخ', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold), padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showPersianDatePicker(context: context, initialDate: _endDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450));
                          if (picked != null) { setState(() => _endDate = picked); _loadData(); }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18, color: AppTheme.gold),
                        label: Text(_endDate != null ? '${_endDate!.month}/${_endDate!.day}' : 'تا تاریخ', style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.gold), padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _expenses.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('هزینه‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.red.withOpacity(0.2), child: const Icon(Icons.receipt, color: Colors.red)),
                              title: Text(expense['category'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(expense['description']?.toString().isNotEmpty == true ? expense['description'] : 'بدون توضیحات', style: const TextStyle(color: AppTheme.textGrey)),
                                const SizedBox(height: 4),
                                Text('تاریخ: ${expense['date']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              ]),
                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('${formatPrice(expense['amount'])} تومان', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteExpense(expense['id']), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
