import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';
import 'license_manager.dart';

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
  final _passwordController = TextEditingController();
  final _commissionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _status = 'active';
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.agentId != null;
    if (_isEditMode) _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllAgents();
    final agent = data.firstWhere((a) => a['id'] == widget.agentId, orElse: () => {});
    if (agent.isNotEmpty) {
      _nameController.text = agent['name']?.toString() ?? '';
      _phoneController.text = agent['phone']?.toString() ?? '';
      _nationalIdController.text = agent['national_id']?.toString() ?? '';
      _passwordController.text = agent['password']?.toString() ?? '';
      _commissionController.text = agent['commission_rate']?.toString() ?? '0';
      _salaryController.text = agent['base_salary']?.toString() ?? '0';
      _notesController.text = agent['notes']?.toString() ?? '';
      _status = agent['status']?.toString() ?? 'active';
      _profileImagePath = agent['profile_image'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final dir = await getApplicationDocumentsDirectory();
      final agentDir = Directory('${dir.path}/agent_images');
      if (!await agentDir.exists()) await agentDir.create(recursive: true);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final savedImage = await File(image.path).copy('${agentDir.path}/$fileName');
      setState(() => _profileImagePath = savedImage.path);
    }
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) return;
    
    // بررسی محدودیت فقط هنگام افزودن (نه ویرایش)
    if (!_isEditMode) {
      final check = await LicenseManager.canAddAgent();
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
                    Text(check['message'] ?? 'امکان ثبت مشاور جدید وجود ندارد', style: const TextStyle(color: AppTheme.textWhite)),
                    const SizedBox(height: 12),
                    const Text('برای افزایش سقف مشاوران، پلن خود را ارتقا دهید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
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
      final agent = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'national_id': _nationalIdController.text.trim(),
        'password': _passwordController.text.trim(),
        'commission_rate': double.tryParse(toEnglishDigits(_commissionController.text)) ?? 0.0,
        'base_salary': double.tryParse(toEnglishDigits(_salaryController.text)) ?? 0.0,
        'status': _status,
        'notes': _notesController.text.trim(),
        'profile_image': _profileImagePath,
      };

      if (_isEditMode) {
        await DatabaseHelper.instance.updateAgent(widget.agentId!, agent);
      } else {
        await DatabaseHelper.instance.insertAgent(agent);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '✓ مشاور ویرایش شد' : '✓ مشاور اضافه شد'), backgroundColor: AppTheme.gold),
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
      appBar: AppBar(
        title: Text(_isEditMode ? 'ویرایش مشاور' : 'افزودن مشاور'), 
        centerTitle: true,
      ),
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
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.cardBlack,
                            backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                            child: _profileImagePath == null ? const Icon(Icons.person, size: 50, color: AppTheme.gold) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(child: Text('برای تغییر تصویر ضربه بزنید', style: TextStyle(color: AppTheme.textGrey, fontSize: 12))),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController, 
                        textDirection: TextDirection.rtl, 
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'نام و نام خانوادگی (نام کاربری)', prefixIcon: Icon(Icons.person, color: AppTheme.gold)), 
                        validator: (v) => v == null || v.trim().isEmpty ? 'نام الزامی است' : null
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController, 
                        textDirection: TextDirection.rtl, 
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock, color: AppTheme.gold)), 
                        validator: (v) => v == null || v.trim().isEmpty ? 'رمز عبور الزامی است' : null
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController, 
                        textDirection: TextDirection.rtl, 
                        keyboardType: TextInputType.phone, 
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone, color: AppTheme.gold)), 
                        validator: (v) => v == null || v.trim().isEmpty ? 'شماره تماس الزامی است' : null
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nationalIdController, 
                        textDirection: TextDirection.rtl, 
                        keyboardType: TextInputType.number, 
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'کد ملی', prefixIcon: Icon(Icons.badge, color: AppTheme.gold))
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _commissionController, 
                              textDirection: TextDirection.rtl, 
                              keyboardType: TextInputType.number, 
                              style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'درصد کمیسیون', prefixIcon: Icon(Icons.percent, color: AppTheme.gold))
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController, 
                              textDirection: TextDirection.rtl, 
                              keyboardType: TextInputType.number, 
                              style: const TextStyle(color: AppTheme.textWhite),
                              decoration: const InputDecoration(labelText: 'حقوق پایه (تومان)', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status, 
                        dropdownColor: AppTheme.cardBlack, 
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on, color: AppTheme.gold)), 
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('فعال')), 
                          DropdownMenuItem(value: 'inactive', child: Text('غیرفعال'))
                        ], 
                        onChanged: (v) => setState(() => _status = v!)
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController, 
                        textDirection: TextDirection.rtl, 
                        maxLines: 3, 
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold), alignLabelWithHint: true)
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50, 
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAgent, 
                          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save, size: 24), 
                          label: Text(_isLoading ? 'در حال ذخیره...' : (_isEditMode ? 'ذخیره تغییرات' : 'افزودن مشاور'), style: const TextStyle(fontSize: 18)), 
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
