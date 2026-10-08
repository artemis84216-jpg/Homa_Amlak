import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';

// تابع کمکی برای تبدیل اعداد فارسی/عربی به انگلیسی
String toEnglishDigits(String str) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    str = str.replaceAll(persian[i], i.toString()).replaceAll(arabic[i], i.toString());
  }
  return str;
}

// فرمت‌کننده برای جدا کردن ۳ رقم ۳ رقم
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
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  
  String _selectedType = 'آپارتمان';
  bool _isLoading = false;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _propertyTypes = ['آپارتمان', 'ویلا', 'زمین', 'تجاری', 'مغازه'];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _images.add(image);
      });
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // تبدیل قیمت به عدد خالص (بدون کاما) برای ذخیره در دیتابیس
      String cleanPrice = toEnglishDigits(_priceController.text.replaceAll(',', ''));
      
      final property = {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'area': double.parse(toEnglishDigits(_areaController.text)),
        'price': double.parse(cleanPrice),
        'address': _addressController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
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
      body: Directionality(
        textDirection: TextDirection.rtl, // راست‌چین کردن کل فرم
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- بخش تصاویر ---
                const Text('تصاویر ملک (اختیاری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._images.map((img) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.remove(img)),
                                child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      )),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.green, size: 32),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                          const Text('دوربین', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: Colors.blue, size: 32),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                          const Text('گالری', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),

                // --- مشخصات ملک ---
                const Text('مشخصات ملک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان ملک',
                    hintText: 'مثلاً: آپارتمان ۸۰ متری نوساز',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'عنوان الزامی است' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'نوع ملک',
                    prefixIcon: Icon(Icons.home_work),
                    border: OutlineInputBorder(),
                  ),
                  items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'متراژ (متر)',
                          prefixIcon: Icon(Icons.square_foot),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'الزامی';
                          if (double.tryParse(toEnglishDigits(v)) == null) return 'عدد نامعتبر';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CommaSeparatorFormatter()], // جداکننده ۳ رقمی
                        decoration: const InputDecoration(
                          labelText: 'قیمت (تومان)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'الزامی';
                          if (double.tryParse(toEnglishDigits(v.replaceAll(',', ''))) == null) return 'عدد نامعتبر';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  textDirection: TextDirection.rtl,
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
                
                const Divider(height: 32),

                // --- مشخصات مالک ---
                const Text('مشخصات مالک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ownerNameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'نام مالک',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ownerPhoneController,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'شماره تماس مالک',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // دکمه ثبت
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProperty,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 24),
                    label: Text(_isLoading ? 'در حال ذخیره...' : 'ثبت ملک', style: const TextStyle(fontSize: 18)),
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
      ),
    );
  }
}
