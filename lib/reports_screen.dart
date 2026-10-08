import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Jalali? _startDate;
  Jalali? _endDate;
  
  int _totalProperties = 0;
  int _soldProperties = 0;
  int _availableProperties = 0;
  double _totalIncome = 0;
  double _totalExpenses = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final properties = await db.query('properties');
    _totalProperties = properties.length;
    _soldProperties = properties.where((p) => p['status'] == 'sold').length;
    _availableProperties = properties.where((p) => p['status'] == 'available').length;

    final contracts = await db.query('contracts');
    _totalIncome = contracts.fold(0.0, (sum, c) => sum + ((c['amount'] as num?)?.toDouble() ?? 0.0));

    final expenses = await db.query('expenses');
    _totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0));

    setState(() => _isLoading = false);
  }

  String _formatNumber(num number) {
    String str = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return str.replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲')
              .replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵')
              .replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸')
              .replaceAll('9', '۹');
  }

  // تابع کمکی برای فرمت تاریخ
  String _formatJalali(Jalali? date) {
    if (date == null) return 'انتخاب تاریخ';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final now = Jalali.now();
    final todayStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('گزارش مالی املاک هما', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('تاریخ گزارش: $todayStr', style: const pw.TextStyle(fontSize: 14)),
                if (_startDate != null && _endDate != null)
                  pw.Text('بازه زمانی: ${_formatJalali(_startDate)} تا ${_formatJalali(_endDate)}', style: const pw.TextStyle(fontSize: 14)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('کل درآمد:'),
                    pw.Text('${_formatNumber(_totalIncome.toInt())} تومان', style: pw.TextStyle(color: PdfColors.green)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('کل هزینه:'),
                    pw.Text('${_formatNumber(_totalExpenses.toInt())} تومان', style: pw.TextStyle(color: PdfColors.red)),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('سود خالص:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${_formatNumber((_totalIncome - _totalExpenses).toInt())} تومان', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: (_totalIncome - _totalExpenses) >= 0 ? PdfColors.green : PdfColors.red)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات مالی'),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بخش فیلتر تاریخ
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_formatJalali(_startDate)),
                                    onPressed: () async {
                                      final picked = await showPersianDatePicker(
                                        context: context,
                                        initialDate: Jalali.now(),
                                        firstDate: Jalali(1380),
                                        lastDate: Jalali(1450),
                                      );
                                      if (picked != null) setState(() => _startDate = picked);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_formatJalali(_endDate)),
                                    onPressed: () async {
                                      final picked = await showPersianDatePicker(
                                        context: context,
                                        initialDate: Jalali.now(),
                                        firstDate: Jalali(1380),
                                        lastDate: Jalali(1450),
                                      );
                                      if (picked != null) setState(() => _endDate = picked);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadReports, 
                              icon: const Icon(Icons.filter_alt),
                              label: const Text('اعمال فیلتر و بروزرسانی'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // کارت آمار
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green[700], size: 28),
                                const SizedBox(width: 8),
                                const Text('آمار مالی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildStatRow('کل درآمد', '${_formatNumber(_totalIncome.toInt())} تومان', Colors.green),
                            _buildStatRow('کل هزینه', '${_formatNumber(_totalExpenses.toInt())} تومان', Colors.red),
                            const Divider(height: 16),
                            _buildStatRow(
                              'سود خالص',
                              '${_formatNumber((_totalIncome - _totalExpenses).toInt())} تومان',
                              _totalIncome - _totalExpenses >= 0 ? Colors.green : Colors.red,
                              isLarge: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // دکمه خروجی PDF
                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _generatePDF,
                        icon: const Icon(Icons.picture_as_pdf, size: 28),
                        label: const Text('دانلود گزارش به صورت PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 18 : 16, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
