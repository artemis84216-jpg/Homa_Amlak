import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'همـا املاک',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب نقش')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('ورود مدیر')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('ورود مشاور')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('ورود مشتری')),
          ],
        ),
      ),
    );
  }
}
