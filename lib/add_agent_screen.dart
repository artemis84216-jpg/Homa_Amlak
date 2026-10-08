import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

String toEnglishDigits(String str) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    str = str.replaceAll(persian[i], i.toString()).replaceAll(arabic[i], i.toString());
  }
  return str;
}

class CommaSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = toEnglishDigits(newValue.text.replaceAll(',', ''));
    if (cleanText.isEmpty) return newValue;
    final intVal = int.tryParse(cleanText);
    if (intVal == null) return oldValue;
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class AddAgentScreen extends StatefulWidget {
  final int? agentId;
  const AddAgentScreen({super.key, this.agentId});

  @override
  State<AddAgentScreen> createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _commissionController = TextEditingController();
  final _salaryController = TextEditingController(); // حالا فرمت‌دهی می‌شود
  final _notesController = TextEditingController();
  
  String _status = 'active';
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.agentId != null;
    if (_isEditMode) _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('agents', where: 'id = ?', whereArgs: [widget.agentId]);
    if (result.isNotEmpty) {
      final data = result.first;
      _nameController.text = data['name']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _nationalIdController.text = data['national_id']?.toString() ?? '';
      
      // فرمت‌دهی حقوق و کمیسیون هنگام بارگذاری
      final salary = data['base_salary']?.toInt() ?? 0;
      _salaryController.text = salary.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      
      final commission = data['commission_rate']?.toInt() ?? 0;
      _commissionController.text = commission.toString();
      
      _notesController.text = data['notes']?.toString() ?? '';
      _status = data['status']?.toString() ?? 'active';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final agent = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'national_id': _nationalIdController.text.trim(),
        'commission_rate': double.parse(toEnglishDigits(_commissionController.text)),
        'base_salary': double.parse(toEnglishDigits(_salaryController.text.replaceAll(',', ''))), // حذف کاما قبل از ذخیره
        'status': _status,
        'notes': _notesController.text.trim(),
      };

      if (_isEditMode) {
        final db = await DatabaseHelper.instance.database;
        await db.update('agents', agent, where: 'id = ?', whereArgs: [widget.agentId]);
      } else {
        await DatabaseHelper.instance.insertAgent(agent);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? '✓ مشاور ویرایش شد' : '✓ مشاور اضافه شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'ویرایش مشاور' : 'افزودن مشاور'),
        backgroundColor: Colors.purple[700],
        centerTitle: true, // وسط‌چین کردن تیتر
        foregroundColor: Colors.white, // سفید کردن آیکون‌ها و متن
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading && _isEditMode
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController, textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'نام الزامی است' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController, textDirection: TextDirection.rtl, keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'شماره تماس الزامی است' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nationalIdController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'کد ملی', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _commissionController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent), border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'الزامی' : (double.tryParse(toEnglishDigits(v)) == null ? 'عدد نامعتبر' : null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController, 
                              textDirection: TextDirection.rtl, 
                              keyboardType: TextInputType.number,
                              inputFormatters: [CommaSeparatorFormatter()], // <-- اصلاح ۱: اضافه شدن فرمت ۳ رقمی
                              decoration: const InputDecoration(labelText: 'حقوق پایه (تومان)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on), border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('فعال')),
                          DropdownMenuItem(value: 'inactive', child: Text('غیرفعال')),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController, textDirection: TextDirection.rtl, maxLines: 3,
                        decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder(), alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAgent,
                          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 24),
                          label: Text(_isLoading ? 'در حال ذخیره...' : (_isEditMode ? 'ذخیره تغییرات' : 'افزودن مشاور'), style: const TextStyle(fontSize: 18, color: Colors.white)), // <-- اصلاح ۲: رنگ متن سفید
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[700], 
                            foregroundColor: Colors.white, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
