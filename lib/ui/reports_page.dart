import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/models/salary.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseController dbController = Get.find();
  final SettingsController settingsController = Get.find();

  final RxString _period = 'Month'.obs;

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateDateRange();
    ever(_period, (_) => _updateDateRange());
  }

  void _updateDateRange() {
    DateTime now = DateTime.now();
    _endDate = now.add(const Duration(days: 1));
    if (_period.value == 'Week') {
      _startDate = now.subtract(const Duration(days: 6));
      _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    } else if (_period.value == 'Month') {
      _startDate = now.subtract(const Duration(days: 29));
      _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
    } else {
      _startDate = DateTime(now.year, 1, 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.shopping_cart), text: 'المشتريات'.tr),
            Tab(icon: Icon(Icons.receipt_long), text: 'المصروفات'.tr),
            Tab(icon: Icon(Icons.payments), text: 'الرواتب'.tr),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
          ),
          Obx(() => _periodToggle()),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchasesReport(),
          _buildExpensesReport(),
          _buildSalariesReport(),
        ],
      ),
    );
  }

  Widget _periodToggle() {
    return Container(
      height: 32,
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleChip('Week'.tr, _period.value == 'Week'),
          _toggleChip('Month'.tr, _period.value == 'Month'),
          _toggleChip('Year'.tr, _period.value == 'Year'),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => _period.value = label == 'Week' ? 'Week' : label == 'Month' ? 'Month' : 'Year',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasesReport() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'المشتريات'.tr} ($_startDate - $_endDate)', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              FutureBuilder<double>(
                future: dbController.getPurchasesTotal(_startDate, _endDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي'.tr, style: TextStyle(fontSize: 16)),
                          Text(
                            settingsController.currencyFormatter(snapshot.data!),
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Text('التوزيع بالفئة'.tr, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              FutureBuilder<Map<String, double>>(
                future: dbController.getPurchasesByCategory(_startDate, _endDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final data = snapshot.data!;
                  if (data.isEmpty) return Text('لا بيانات'.tr);
                  return _buildPieChart(data.entries.toList(), Colors.indigo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesReport() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'المصروفات'.tr} ($_startDate - $_endDate)', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              Obx(() => Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإجمالي'.tr, style: TextStyle(fontSize: 16)),
                      Text(
                        settingsController.currencyFormatter(dbController.getExpenses(_startDate, _endDate)),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )),
              SizedBox(height: 24),
              Text('التوزيع'.tr, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              // Placeholder pie for expenses (keyword based)
              _buildExpensesPie(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesPie() {
    // Simple keyword-based grouping
    Map<String, double> data = {};
    for (var e in dbController.expenses.where((e) => e.date.isAfter(_startDate) && e.date.isBefore(_endDate))) {
      String cat = 'أخرى'.tr;
      final desc = e.description.toLowerCase();
      if (desc.contains('كهرباء')) cat = 'كهرباء'.tr;
      else if (desc.contains('إيجار') || desc.contains('rent')) cat = 'إيجار'.tr;
      else if (desc.contains('وقود') || desc.contains('petrol')) cat = 'وقود'.tr;
      else if (desc.contains('صيانة') || desc.contains('maintenance')) cat = 'صيانة'.tr;
      data[cat] = (data[cat] ?? 0) + e.amount;
    }
    return _buildPieChart(data.entries.toList(), Colors.orange);
  }

  Widget _buildSalariesReport() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'الرواتب'.tr} ($_startDate - $_endDate)', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              FutureBuilder<double>(
                future: dbController.getSalariesTotal(_startDate, _endDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي'.tr, style: TextStyle(fontSize: 16)),
                          Text(
                            settingsController.currencyFormatter(snapshot.data!),
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Text('التوزيع بالموظف'.tr, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              FutureBuilder<Map<String, double>>(
                future: dbController.getSalariesByEmployee(_startDate, _endDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final data = snapshot.data!;
                  if (data.isEmpty) return Text('لا بيانات'.tr);
                  return _buildPieChart(data.entries.toList(), Colors.purple);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> data, Color color) {
    final total = data.fold(0.0, (sum, e) => sum + e.value);
    final slices = data.map((e) => PieChartSectionData(
      color: color.withOpacity(0.7 + (data.indexOf(e) * 0.1)),
      value: e.value,
      title: '${e.key}\n${settingsController.currencyFormatter(e.value)}',
      radius: 60,
      titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
    )).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: slices,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  void _generatePDF() async {
    final pdf = pw.Document();
    final localeCode = Get.locale!.languageCode;
    final currencyFormat = NumberFormat.currency(locale: localeCode, symbol: settingsController.currencySymbol.value ?? '');
    final dateFormat = DateFormat('yyyy-MM-dd', localeCode);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('التقارير المالية'.tr, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('${'الفترة'.tr}: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}'),
            pw.SizedBox(height: 20),
            pw.Text('المشتريات: ${currencyFormat.format(await dbController.getPurchasesTotal(_startDate, _endDate))}'),
            pw.Text('المصروفات: ${currencyFormat.format(dbController.getExpenses(_startDate, _endDate))}'),
            pw.Text('الرواتب: ${currencyFormat.format(await dbController.getSalariesTotal(_startDate, _endDate))}'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
