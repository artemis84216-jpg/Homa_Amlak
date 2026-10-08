import 'package:flutter/material.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت قراردادها'),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 16),
              const Text('لیست قراردادها خالی است', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('قراردادهای ثبت‌شده در اینجا نمایش داده می‌شوند', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فرم ثبت قرارداد به زودی اضافه می‌شود')),
          );
        },
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ثبت قرارداد جدید'),
      ),
    );
  }
}
