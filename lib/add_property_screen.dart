import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'database_helper.dart';
import 'app_utils.dart';
import 'license_manager.dart';

class AddPropertyScreen extends StatefulWidget {
  final int? propertyId;
  final Map<String, dynamic>? currentAgent;
  const AddPropertyScreen({super.key, this.propertyId, this.currentAgent});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _addressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _agentNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  
  String _selectedType = 'آپارتمان';
  String _listingType = 'sale';
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isEditMode = false;
  final List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();
  final List<String> _propertyTypes = ['آپارتمان', 'ویلا', 'زمین', 'تجاری', 'مغازه'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.propertyId != null;
    if (widget.currentAgent != null) {
      _agentNameController.text = widget.currentAgent!['name'] ?? '';
      _agentPhoneController.text = widget.currentAgent!['phone'] ?? '';
    }
    if (_isEditMode) _loadPropertyData();
  }

  Future<void> _loadPropertyData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getPropertyById(widget.propertyId!);
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _selectedType = data['type'] ?? 'آپارتمان';
      _listingType = data['listing_type'] ?? 'sale';
      _areaController.text = data['area']?.toString() ?? '';
      final price = data['price']?.toInt() ?? 0;
      _priceController.text = price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      final monthlyRent = data['monthly_rent']?.toInt() ?? 0;
      _monthlyRentController.text = monthlyRent > 0 
          ? monthlyRent.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')
          : '';
      _addressController.text = data['address'] ?? '';
      _ownerNameController.text = data['owner_name'] ?? '';
      _ownerPhoneController.text = data['owner_phone'] ?? '';
      _agentNameController.text = data['agent_name'] ?? _agentNameController.text;
      _agentPhoneController.text = data['agent_phone'] ?? _agentPhoneController.text;
      _bedroomsController.text = data['bedrooms']?.toString() ?? '';
      _floorController.text = data['floor']?.toString() ?? '';
      _totalFloorsController.text = data['total_floors']?.toString() ?? '';
      _isPublic = data['is_public'] == 1;
      
      if (data['images'] != null && data['images'] != '') {
        try {
          final List<dynamic> paths = jsonDecode(data['images']);
          setState(() => _imagePaths.addAll(paths.cast<String>()));
        } catch (e) {}
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final dir = await getApplicationDocumentsDirectory();
      final propertyDir = Directory('${dir.path}/property_images');
      if (!await propertyDir.exists()) await propertyDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final savedImage = await File(image.path).copy('${propertyDir.path}/$fileName');
      setState(() => _imagePaths.add(savedImage.path));
    }
  }

  void _removeImage(int index) {
    final file = File(_imagePaths[index]);
    if (file.existsSync()) file.deleteSync();
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    
    // بررسی محدودیت فقط هنگام افزودن (نه ویرایش)
    if (!_isEditMode) {
      final check = await LicenseManager.canAddProperty();
      if (!check['allowed']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.cardBlack,
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red, size: 28),
                    SizedBox(width: 8),
                    Text('محدودیت پلن', style: TextStyle(color: Colors.red)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(check['message'] ?? 'امکان ثبت ملک جدید وجود ندارد', style: const TextStyle(color: AppTheme.textWhite)),
                    const SizedBox(height: 12),
                    const Text('برای افزایش سقف فایل ملک، پلن خود را ارتقا دهید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.gold)),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }
    }
    
    setState(() => _isLoading = true);

    try {
      String cleanPrice = toEnglishDigits(_priceController.text.replaceAll(',', ''));
      String cleanMonthlyRent = toEnglishDigits(_monthlyRentController.text.replaceAll(',', ''));
      
      final property = {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'area': double.parse(toEnglishDigits(_areaController.text)),
        'price': double.parse(cleanPrice),
        'monthly_rent': _listingType == 'rent' ? double.parse(cleanMonthlyRent.isEmpty ? '0' : cleanMonthlyRent) : 0,
        'address': _addressController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
        'agent_name': _agentNameController.text.trim(),
        'agent_phone': _agentPhoneController.text.trim(),
        'bedrooms': int.tryParse(toEnglishDigits(_bedroomsController.text)) ?? 0,
        'floor': int.tryParse(toEnglishDigits(_floorController.text)) ?? 0,
        'total_floors': int.tryParse(toEnglishDigits(_totalFloorsController.text)) ?? 0,
        'listing_type': _listingType,
        'images': jsonEncode(_imagePaths),
        'is_public': _isPublic ? 1 : 0,
        'status': 'available',
      };

      if (_isEditMode) {
        await DatabaseHelper.instance.updateProperty(widget.propertyId!, property);
      } else {
        await DatabaseHelper.instance.insertProperty(property);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '✓ ملک ویرایش شد' : '✓ ملک ثبت شد'), backgroundColor: AppTheme.gold)
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: Text(_isEditMode ? 'ویرایش ملک' : 'ثبت ملک جدید'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading && _isEditMode 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) 
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey, 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [
                      const Text('تصاویر ملک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100, 
                        child: ListView(
                          scrollDirection: Axis.horizontal, 
                          children: [
                            ..._imagePaths.asMap().entries.map((entry) {
                              final index = entry.key; final path = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8), 
                                child: Stack(
                                  children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover)),
                                    Positioned(
                                      top: 0, right: 0, 
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index), 
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white))
                                      )
                                    ),
                                  ]
                                )
                              );
                            }),
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(icon: const Icon(Icons.camera_alt, color: AppTheme.gold, size: 32), onPressed: () => _pickImage(ImageSource.camera)), 
                              const Text('دوربین', style: TextStyle(fontSize: 12, color: AppTheme.textGrey))
                            ]),
                            const SizedBox(width: 8),
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(icon: const Icon(Icons.photo_library, color: AppTheme.gold, size: 32), onPressed: () => _pickImage(ImageSource.gallery)), 
                              const Text('گالری', style: TextStyle(fontSize: 12, color: AppTheme.textGrey))
                            ]),
                          ]
                        )
                      ),
                      const Divider(height: 32, color: AppTheme.gold),
                      const Text('نوع معامله', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _listingType = 'sale'),
                              icon: const Icon(Icons.sell),
                              label: const Text('فروش'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _listingType == 'sale' ? AppTheme.gold : AppTheme.cardBlack,
                                foregroundColor: _listingType == 'sale' ? Colors.black : AppTheme.textWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppTheme.gold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(() => _listingType = 'rent'),
                              icon: const Icon(Icons.key),
                              label: const Text('اجاره'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _listingType == 'rent' ? AppTheme.gold : AppTheme.cardBlack,
                                foregroundColor: _listingType == 'rent' ? Colors.black : AppTheme.textWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppTheme.gold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: AppTheme.gold),
                      const Text('مشخصات ملک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController, textDirection: TextDirection.rtl, style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'عنوان ملک', prefixIcon: Icon(Icons.title, color: AppTheme.gold)), 
                        validator: (v) => v == null || v.trim().isEmpty ? 'عنوان الزامی است' : null
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'نوع ملک', prefixIcon: Icon(Icons.home_work, color: AppTheme.gold)), 
                        items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(), 
                        onChanged: (v) => setState(() => _selectedType = v!)
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'متراژ (متر)', prefixIcon: Icon(Icons.square_foot, color: AppTheme.gold)), 
                              validator: (v) => v == null || v.isEmpty ? 'الزامی' : (double.tryParse(toEnglishDigits(v)) == null ? 'عدد نامعتبر' : null)
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                              inputFormatters: [CommaSeparatorFormatter()], 
                              decoration: InputDecoration(labelText: _listingType == 'sale' ? 'قیمت فروش (تومان)' : 'رهن کامل (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold)), 
                              validator: (v) => v == null || v.isEmpty ? 'الزامی' : (double.tryParse(toEnglishDigits(v.replaceAll(',', ''))) == null ? 'عدد نامعتبر' : null)
                            )
                          ),
                        ],
                      ),
                      if (_listingType == 'rent') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _monthlyRentController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                          inputFormatters: [CommaSeparatorFormatter()], 
                          decoration: const InputDecoration(labelText: 'اجاره ماهیانه (تومان)', prefixIcon: Icon(Icons.money, color: AppTheme.gold)), 
                          validator: (v) {
                            if (_listingType == 'rent' && (v == null || v.isEmpty)) return 'اجاره ماهیانه الزامی است';
                            if (v != null && v.isNotEmpty && double.tryParse(toEnglishDigits(v.replaceAll(',', ''))) == null) return 'عدد نامعتبر';
                            return null;
                          }
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bedroomsController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'تعداد خواب', prefixIcon: Icon(Icons.bed, color: AppTheme.gold)), 
                            )
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _floorController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'طبقه', prefixIcon: Icon(Icons.layers, color: AppTheme.gold)), 
                            )
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _totalFloorsController, textDirection: TextDirection.rtl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'کل طبقات', prefixIcon: Icon(Icons.apartment, color: AppTheme.gold)), 
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController, textDirection: TextDirection.rtl, maxLines: 3, style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'آدرس', prefixIcon: Icon(Icons.location_on, color: AppTheme.gold), alignLabelWithHint: true), 
                        validator: (v) => v == null || v.trim().isEmpty ? 'آدرس الزامی است' : null
                      ),
                      const Divider(height: 32, color: AppTheme.gold),
                      const Text('مشخصات مالک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 12),
                      TextFormField(controller: _ownerNameController, textDirection: TextDirection.rtl, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام مالک', prefixIcon: Icon(Icons.person_outline, color: AppTheme.gold))),
                      const SizedBox(height: 16),
                      TextFormField(controller: _ownerPhoneController, textDirection: TextDirection.rtl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس مالک', prefixIcon: Icon(Icons.phone, color: AppTheme.gold))),
                      const Divider(height: 32, color: AppTheme.gold),
                      const Text('مشخصات مشاور ثبت‌کننده', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _agentNameController, textDirection: TextDirection.rtl, style: const TextStyle(color: AppTheme.textWhite), readOnly: true,
                        decoration: const InputDecoration(labelText: 'نام مشاور', prefixIcon: Icon(Icons.badge, color: AppTheme.gold), filled: true, fillColor: Color(0xFF333333))
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _agentPhoneController, textDirection: TextDirection.rtl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), readOnly: true,
                        decoration: const InputDecoration(labelText: 'شماره تماس مشاور', prefixIcon: Icon(Icons.phone_android, color: AppTheme.gold), filled: true, fillColor: Color(0xFF333333))
                      ),
                      const Divider(height: 32, color: AppTheme.gold),
                      SwitchListTile(
                        title: const Text('نمایش عمومی در پنل مشتری', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        subtitle: const Text('در صورت فعال بودن، مشتریان این ملک را خواهند دید', style: TextStyle(color: AppTheme.textGrey)),
                        value: _isPublic,
                        activeColor: AppTheme.gold,
                        onChanged: (val) => setState(() => _isPublic = val),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50, 
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveProperty, 
                          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save, size: 24), 
                          label: Text(_isLoading ? 'در حال ذخیره...' : (_isEditMode ? 'ذخیره تغییرات' : 'ثبت ملک'), style: const TextStyle(fontSize: 18)), 
                        )
                      ),
                    ]
                  )
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
