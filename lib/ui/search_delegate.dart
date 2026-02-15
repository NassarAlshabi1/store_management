import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/controllers/settings_controller.dart';
import 'package:store_management/models/purchase.dart';
import 'package:store_management/models/expense.dart';
import 'package:store_management/models/salary.dart';
import 'package:store_management/models/urgent_order.dart';
import 'package:store_management/ui/purchases_page.dart';
import 'package:store_management/ui/expenses_page.dart';
import 'package:store_management/ui/salaries_page.dart';
import 'package:store_management/ui/urgent_orders_page.dart';

class SearchDelegateHelper extends SearchDelegate {
  DatabaseController databaseController = Get.find();
  SettingsController settingsController = Get.find();

  List results = [];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _buildResults();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultTile(results[index]),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _buildResults();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultTile(results[index]),
    );
  }

  void _buildResults() {
    results = [];
    final q = query.toLowerCase();

    // Purchases
    results.addAll(databaseController.getPurchases().then((purchases) => purchases
      .where((p) => p.supplierName.toLowerCase().contains(q) || p.receiptNumber.toLowerCase().contains(q))
      .take(5)
      .map((p) => {'type': 'purchase', 'data': p})));

    // Expenses
    results.addAll(databaseController.expenses
      .where((e) => e.description.toLowerCase().contains(q))
      .take(5)
      .map((e) => {'type': 'expense', 'data': e}));

    // Salaries
    databaseController.getSalaries().then((salaries) {
      results.addAll(salaries
        .where((s) => s.employeeName.toLowerCase().contains(q))
        .take(5)
        .map((s) => {'type': 'salary', 'data': s}));
    });

    // Urgent Orders
    results.addAll(databaseController.getUrgentOrders().then((orders) => orders
      .where((o) => o.name.toLowerCase().contains(q))
      .take(5)
      .map((o) => {'type': 'urgent_order', 'data': o})));
  }

  Widget _buildResultTile(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final data = item['data'];

    IconData icon;
    String title;
    String subtitle;
    VoidCallback? onTap;

    switch (type) {
      case 'purchase':
        final p = data as Purchase;
        icon = Icons.shopping_cart;
        title = p.supplierName;
        subtitle = '${p.receiptNumber} - ${settingsController.currencyFormatter(p.totalAmount)}';
        onTap = () => Get.to(() => PurchasesPage(query: query));
        break;
      case 'expense':
        final e = data as Expense;
        icon = Icons.receipt_long;
        title = e.description;
        subtitle = '${e.getDate()} - ${settingsController.currencyFormatter(e.amount)}';
        onTap = () => Get.to(() => ExpensesPage());
        break;
      case 'salary':
        final s = data as Salary;
        icon = Icons.payments;
        title = s.employeeName;
        subtitle = '${s.month.toString().substring(0,7)} - ${settingsController.currencyFormatter(s.totalSalary)}';
        onTap = () => Get.to(() => SalariesPage());
        break;
      case 'urgent_order':
        final o = data as UrgentOrder;
        icon = Icons.priority_high;
        title = o.name;
        subtitle = o.date.toString().substring(0,10);
        onTap = () => Get.to(() => UrgentOrdersPage());
        break;
      default:
        return SizedBox.shrink();
    }

    return ListTile(
      leading: CircleAvatar(child: Icon(icon, color: Colors.white)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
