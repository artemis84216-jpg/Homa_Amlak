import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class RequestViewingScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  const RequestViewingScreen({super.key, required this.property});

  @override
  State<RequestViewingScreen> createState() => _RequestViewingScreenState();
}

class _RequestViewingScreenState extends State<RequestViewingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  Jalali? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  String _formatJalali(Jalali? date) {
    if (date == null) return 'انتخاب تاریخ';
    return '${toPersianDigits(date.year.toString())}/${toPersianDigits(date.month.toString().padLeft(2, '0'))}/${toPersianDigits(date.day.toString().padLeft(2, '0'))}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'انتخاب ساعت';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${toPersianDigits(hour)}:${toPersianDigits(minute)}';
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً تاریخ و ساعت را انتخاب کنید'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewing = {
        'property_id': widget.property['id'],
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'viewing_date': _formatJalali(_selectedDate),
        'viewing_time': _formatTime(_selectedTime),
        'notes': _notesController.text.trim(),
        'status': 'pending',
      };

      await DatabaseHelper.instance.insertViewing(viewing);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ درخواست بازدید شما ثبت شد. مشاور به زودی با شما تماس خواهد گرفت.'),
            backgroundColor: AppTheme.gold,
            duration: Duration(seconds: 3),
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
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('درخواست بازدید'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اطلاعات ملک
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.home, color: AppTheme.gold, size: 20),
                          SizedBox(width: 8),
                          Text('ملک مورد بازدید', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(widget.property['title'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('مشاور: ${widget.property['agent_name'] ?? "نامشخص"}', style: const TextStyle(color: AppTheme.textGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('مشخصات شما', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'نام و نام خانوادگی', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'نام الزامی است' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone, color: AppTheme.gold)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'شماره تماس الزامی است' : null,
                ),
                const SizedBox(height: 24),

                const Text('زمان پیشنهادی بازدید', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showPersianDatePicker(
                            context: context,
                            initialDate: Jalali.now(),
                            firstDate: Jalali.now(),
                            lastDate: Jalali(1450),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.gold,
                                    onPrimary: Colors.black,
                                    surface: AppTheme.cardBlack,
                                    onSurface: AppTheme.textWhite,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, color: AppTheme.gold),
                        label: Text(_formatJalali(_selectedDate), style: const TextStyle(color: AppTheme.textWhite)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.gold),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.gold,
                                    onPrimary: Colors.black,
                                    surface: AppTheme.cardBlack,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                        icon: const Icon(Icons.access_time, color: AppTheme.gold),
                        label: Text(_formatTime(_selectedTime), style: const TextStyle(color: AppTheme.textWhite)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.gold),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'توضیحات (اختیاری)',
                    hintText: 'مثلاً: ترجیحاً عصرها...',
                    prefixIcon: Icon(Icons.notes, color: AppTheme.gold),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitRequest,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.send, size: 24),
                    label: Text(_isLoading ? 'در حال ارسال...' : 'ثبت درخواست بازدید', style: const TextStyle(fontSize: 18)),
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
