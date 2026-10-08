import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت هزینه‌ها'),
        backgroundColor: Colors.red[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text('لیست هزینه‌ها خالی است', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('هزینه‌های ثبت‌شده در اینجا نمایش داده می‌شوند', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فرم ثبت هزینه به زودی اضافه می‌شود')),
          );
        },
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ثبت هزینه جدید'),
      ),
    );
  }
}
