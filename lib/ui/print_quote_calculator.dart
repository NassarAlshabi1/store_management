import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/print_quote.dart';
import 'package:store_management/utils/app_constants.dart';

class PrintQuoteCalculator extends StatefulWidget {
  const PrintQuoteCalculator({super.key});

  @override
  State<PrintQuoteCalculator> createState() => _PrintQuoteCalculatorState();
}

class _PrintQuoteCalculatorState extends State<PrintQuoteCalculator> {
  final DatabaseController dbController = Get.find();
  final SettingsController settingsController = Get.find();

  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pagesController = TextEditingController();

  String? _paperType;
  String _format = 'A4';
  bool _isColor = false;
  bool _doubleSided = false;
  String _binding = 'لا يوجد';

  List<PaperStock> papers = [];
  double _paperCost = 0;
  double _inkCost = 0;
  double _laborCost = 0;
  double _totalCost = 0;
  double _suggestedPrice = 0;

  final Map<String, double> _formatSheets = {
    'A0': 16.0,
    'A1': 8.0,
    'A2': 4.0,
    'A3': 2.0,
    'A4': 1.0,
  };

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    papers = await dbController.getPaperStock();
    setState(() {});
  }

  void _calculate() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final pages = int.tryParse(_pagesController.text) ?? 0;
    if (qty == 0 || pages == 0 || _paperType == null) return;

    final paper = papers.firstWhere((p) => p.paperType == _paperType, orElse: () => papers.first);
    final sheetsPerPage = _formatSheets[_format] ?? 1.0;
    final sides = _doubleSided ? 1.0 : 2.0;
    final waste = 1.1; // 10% waste

    _paperCost = qty * pages * sides * sheetsPerPage * waste * paper.unitCost;
    _inkCost = qty * pages * (_isColor ? 0.05 : 0.02); // per page
    _laborCost = qty * pages * 0.01; // per page

    _totalCost = _paperCost + _inkCost + _laborCost;
    _suggestedPrice = _totalCost * 1.5; // 50% margin

    setState(() {});
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      final quote = PrintQuote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: _customerController.text,
        paperType: _paperType!,
        format: _format,
        pages: int.parse(_pagesController.text),
        isColor: _isColor,
        doubleSided: _doubleSided,
        quantity: int.parse(_quantityController.text),
        binding: _binding,
        paperCost: _paperCost,
        inkCost: _inkCost,
        laborCost: _laborCost,
        totalCost: _totalCost,
        suggestedPrice: _suggestedPrice,
      );

      await dbController.addPrintQuote(quote);
      Get.snackbar('نجاح', 'تم حفظ عرض الأسعار بنجاح');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حاسبة عرض أسعار'.tr)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerController,
              decoration: inputDecoration.copyWith(labelText: 'اسم العميل'.tr),
              validator: (v) => v!.isEmpty ? 'مطلوب'.tr : null,
            ),
            verSpace,
            DropdownButtonFormField<String>(
              value: _paperType,
              decoration: inputDecoration.copyWith(labelText: 'نوع الورق'.tr),
              items: papers.map((p) => DropdownMenuItem(value: p.paperType, child: Text(p.paperType))).toList(),
              onChanged: (v) {
                setState(() => _paperType = v);
                _calculate();
              },
            ),
            verSpace,
            DropdownButtonFormField<String>(
              value: _format,
              decoration: inputDecoration.copyWith(labelText: 'المقاس'.tr),
              items: ['A0', 'A1', 'A2', 'A3', 'A4'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                setState(() => _format = v!);
                _calculate();
              },
            ),
            verSpace,
            TextFormField(
              controller: _pagesController,
              decoration: inputDecoration.copyWith(labelText: 'عدد الصفحات'.tr),
              keyboardType: TextInputType.number,
              validator: Validatorless.required('مطلوب'.tr),
              onChanged: (_) => _calculate(),
            ),
            verSpace,
            SwitchListTile(
              title: Text('ملون'.tr),
              value: _isColor,
              onChanged: (v) {
                setState(() => _isColor = v);
                _calculate();
              },
            ),
            SwitchListTile(
              title: Text('طبع من الجهتين'.tr),
              value: _doubleSided,
              onChanged: (v) {
                setState(() => _doubleSided = v);
                _calculate();
              },
            ),
            verSpace,
            DropdownButtonFormField<String>(
              value: _binding,
              decoration: inputDecoration.copyWith(labelText: 'التجليد'.tr),
              items: ['لا يوجد', 'دبوس', 'مثالي', 'سبرال'].map((b) => DropdownMenuItem(value: b, child: Text(b.tr))).toList(),
              onChanged: (v) => setState(() => _binding = v!),
            ),
            verSpace,
            TextFormField(
              controller: _quantityController,
              decoration: inputDecoration.copyWith(labelText: 'الكمية'.tr),
              keyboardType: TextInputType.number,
              validator: Validatorless.required('مطلوب'.tr),
              onChanged: (_) => _calculate(),
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('تكلفة الورق'.tr),
                      Text(settingsController.currencyFormatter(_paperCost)),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('تكلفة الحبر'.tr),
                      Text(settingsController.currencyFormatter(_inkCost)),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('تكلفة العمالة'.tr),
                      Text(settingsController.currencyFormatter(_laborCost)),
                    ]),
                    Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('التكلفة الإجمالية'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(settingsController.currencyFormatter(_totalCost), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ]),
                    SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('سعر مقترح (50% هامش)'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(settingsController.currencyFormatter(_suggestedPrice), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveQuote,
                child: Text('حفظ عرض الأسعار'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
