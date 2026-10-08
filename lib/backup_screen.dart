import 'package:flutter/material.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پشتیبان‌گیری'),
        backgroundColor: Colors.indigo[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 80, color: Colors.indigo[700]),
                const SizedBox(height: 24),
                const Text('پشتیبان‌گیری از دیتابیس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('آخرین پشتیبان‌گیری: انجام نشده', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ فایل پشتیبان با موفقیت در حافظه ذخیره شد'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('ایجاد فایل پشتیبان جدید', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لطفاً فایل پشتیبان را انتخاب کنید')),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('بازیابی از فایل پشتیبان', style: TextStyle(fontSize: 16)),
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
