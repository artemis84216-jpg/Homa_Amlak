import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'database_helper.dart';
import 'invitation_helper.dart';
import 'app_utils.dart';

class AgentGenerateCustomerQrScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  const AgentGenerateCustomerQrScreen({super.key, required this.agentData});

  @override
  State<AgentGenerateCustomerQrScreen> createState() => _AgentGenerateCustomerQrScreenState();
}

class _AgentGenerateCustomerQrScreenState extends State<AgentGenerateCustomerQrScreen> {
  final _customerNameController = TextEditingController();
  final _apkUrlController = TextEditingController(text: 'https://homa-amlak.ir/download/customer.apk');
  String? _generatedCode;
  String? _qrContent;
  bool _isLoading = false;

  Future<void> _generateInvitation() async {
    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نام مشتری را وارد کنید'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final code = InvitationHelper.generateInvitationCode();
    final content = InvitationHelper.generateQRContent(
      invitationCode: code,
      apkDownloadUrl: _apkUrlController.text.trim(),
    );

    await DatabaseHelper.instance.insertInvitation({
      'code': code,
      'inviter_name': widget.agentData['name'] ?? 'مشاور',
      'inviter_role': 'agent',
      'target_role': 'customer',
      'apk_download_url': _apkUrlController.text.trim(),
      'is_used': 0,
    });

    setState(() {
      _generatedCode = code;
      _qrContent = content;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('دعوت مشتری جدید'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.qr_code_2, color: AppTheme.gold, size: 24), SizedBox(width: 8), Text('راهنما', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                    SizedBox(height: 8),
                    Text('۱. نام مشتری را وارد کنید', style: TextStyle(color: AppTheme.textWhite)),
                    SizedBox(height: 4),
                    Text('۲. لینک دانلود APK اپ مشتری را وارد کنید', style: TextStyle(color: AppTheme.textWhite)),
                    SizedBox(height: 4),
                    Text('۳. QR کد را برای مشتری ارسال کنید', style: TextStyle(color: AppTheme.textWhite)),
                    SizedBox(height: 4),
                    Text('۴. مشتری با اسکن QR کد، اپ را نصب می‌کند', style: TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _customerNameController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'نام مشتری', prefixIcon: Icon(Icons.person, color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apkUrlController,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                decoration: const InputDecoration(labelText: 'لینک دانلود APK مشتری', prefixIcon: Icon(Icons.link, color: AppTheme.gold), hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateInvitation,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.qr_code_2),
                label: const Text('تولید QR کد دعوت'),
              ),

              if (_qrContent != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrContent!,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text('کد دعوت: ${_generatedCode!}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      Text('مشاور: ${widget.agentData['name']}', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ کد دعوت کپی شد')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('کپی کد'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _qrContent!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ محتوای QR کپی شد')));
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('کپی QR'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
