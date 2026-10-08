import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedType = 'آپارتمان';
  bool _isLoading = false;

  final List<String> _propertyTypes = ['آپارتمان', 'ویلا', 'زمین', 'تجاری', 'مغازه'];

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final property = {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'area': double.parse(_areaController.text),
        'price': double.parse(_priceController.text),
        'address': _addressController.text.trim(),
        'status': 'available',
      };

      await DatabaseHelper.instance.insertProperty(property);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ ملک با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ثبت: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت ملک جدید'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عنوان
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان ملک',
                  hintText: 'مثلاً: آپارتمان ۸۰ متری در سعادت‌آباد',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'عنوان الزامی است' : null,
              ),
              const SizedBox(height: 16),

              // نوع ملک
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع ملک',
                  prefixIcon: Icon(Icons.home_work),
                  border: OutlineInputBorder(),
                ),
                items: _propertyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),

              // متراژ و قیمت در کنار هم
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'متراژ (متر)',
                        prefixIcon: Icon(Icons.square_foot),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'الزامی';
                        if (double.tryParse(v) == null) return 'عدد نامعتبر';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'قیمت (تومان)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'الزامی';
                        if (double.tryParse(v) == null) return 'عدد نامعتبر';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // آدرس
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'آدرس',
                  hintText: 'آدرس کامل ملک...',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'آدرس الزامی است' : null,
              ),
              const SizedBox(height: 24),

              // دکمه ثبت
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProperty,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 24),
                  label: Text(
                    _isLoading ? 'در حال ذخیره...' : 'ثبت ملک',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
