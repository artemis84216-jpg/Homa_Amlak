import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class AdminDealRegistrationScreen extends StatefulWidget {
  const AdminDealRegistrationScreen({super.key});

  @override
  State<AdminDealRegistrationScreen> createState() => _AdminDealRegistrationScreenState();
}

class _AdminDealRegistrationScreenState extends State<AdminDealRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  
  List<Map<String, dynamic>> _properties = [];
  Map<String, dynamic>? _selectedProperty;
  String _dealType = 'sale';
  bool _isLoading = false;
  bool _isLoadingProps = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoadingProps = true);
    final data = await DatabaseHelper.instance.getAvailableProperties();
    setState(() {
      _properties = data;
      _isLoadingProps = false;
    });
  }

  Future<void> _openKhodnevis() async {
    final Uri url = Uri.parse('https://khodnevis.mrud.ir/');
    try {
      // حذف canLaunchUrl و استفاده مستقیم برای دور زدن محدودیت‌های اندروید
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در باز کردن مرورگر: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveDeal() async {
    if (!_formKey.currentState!.validate() || _selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً یک ملک انتخاب کنید'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanAmount = toEnglishDigits(_amountController.text.replaceAll(',', ''));
      
      await DatabaseHelper.instance.registerDeal(
        propertyId: _selectedProperty!['id'],
        propertyTitle: _selectedProperty!['title'],
        agentName: _selectedProperty!['agent_name'] ?? 'نامشخص',
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        dealType: _dealType,
        amount: double.parse(cleanAmount.isEmpty ? '0' : cleanAmount),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ معامله ثبت و وضعیت ملک تغییر کرد'), backgroundColor: AppTheme.gold),
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
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('ثبت معامله جدید'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // دکمه سامانه خودنویس
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gavel, color: Colors.blue, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('سامانه خودنویس وزارت راه', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('برای دریافت کد رهگیری، ابتدا سامانه را باز کنید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openKhodnevis,
                          icon: const Icon(Icons.open_in_new, size: 20),
                          label: const Text('باز کردن سامانه خودنویس', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('۱. انتخاب ملک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                
                if (_isLoadingProps)
                  const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                else if (_properties.isEmpty)
                  const Center(child: Text('هیچ ملک موجودی برای ثبت معامله وجود ندارد', style: TextStyle(color: AppTheme.textGrey)))
                else
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProperty,
                    dropdownColor: AppTheme.cardBlack,
                    decoration: const InputDecoration(
                      labelText: 'انتخاب ملک موجود',
                      prefixIcon: Icon(Icons.home, color: AppTheme.gold),
                      border: OutlineInputBorder(),
                    ),
                    items: _properties.map((p) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: p,
                        child: Text(p['title'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProperty = val;
                        if (val != null && val['listing_type'] == 'rent') {
                          _dealType = 'rent';
                        } else if (val != null) {
                          _dealType = 'sale';
                        }
                      });
                    },
                    validator: (v) => v == null ? 'انتخاب ملک الزامی است' : null,
                  ),
                
                // نمایش کارت اطلاعات ملک انتخاب شده
                if (_selectedProperty != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack, 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gold, width: 1)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedProperty!['title'] ?? '', style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.textGrey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_selectedProperty!['address'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.attach_money, size: 16, color: AppTheme.textGrey),
                          const SizedBox(width: 4),
                          Text('${formatPrice(_selectedProperty!['price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontSize: 14, fontWeight: FontWeight.bold)),
                        ]),
                        const Divider(color: AppTheme.gold, height: 20),
                        Row(children: [
                          const Icon(Icons.badge, color: AppTheme.gold, size: 18),
                          const SizedBox(width: 8),
                          Text('مشاور ثبت‌کننده: ${_selectedProperty!['agent_name'] ?? "نامشخص"}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Text('۲. مشخصات طرف معامله (مشتری)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerNameController,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'نام و نام خانوادگی مشتری', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'نام مشتری الزامی است' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'شماره تماس مشتری', prefixIcon: Icon(Icons.phone, color: AppTheme.gold)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'شماره تماس الزامی است' : null,
                ),

                const SizedBox(height: 24),
                const Text('۳. جزئیات معامله', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _dealType = 'sale'),
                        icon: const Icon(Icons.sell, size: 18),
                        label: const Text('فروش', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dealType == 'sale' ? AppTheme.gold : AppTheme.cardBlack,
                          foregroundColor: _dealType == 'sale' ? Colors.black : AppTheme.textWhite,
                          side: const BorderSide(color: AppTheme.gold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _dealType = 'rent'),
                        icon: const Icon(Icons.key, size: 18),
                        label: const Text('اجاره', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dealType == 'rent' ? AppTheme.gold : AppTheme.cardBlack,
                          foregroundColor: _dealType == 'rent' ? Colors.black : AppTheme.textWhite,
                          side: const BorderSide(color: AppTheme.gold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textWhite),
                  inputFormatters: [CommaSeparatorFormatter()],
                  decoration: InputDecoration(
                    labelText: _dealType == 'sale' ? 'مبلغ نهایی فروش (تومان)' : 'مبلغ کل رهن و اجاره (تومان)',
                    prefixIcon: const Icon(Icons.attach_money, color: AppTheme.gold),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'مبلغ الزامی است' : null,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveDeal,
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                    label: Text(_isLoading ? 'در حال ثبت...' : 'ثبت نهایی معامله و تغییر وضعیت ملک', style: const TextStyle(fontSize: 16)),
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
