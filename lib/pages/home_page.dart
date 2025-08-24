import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

import 'widgets/expense_input_modal.dart';
import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomePage({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _totalIncome = 0.0;
  double _totalSpent = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _topCategories = {};
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // initState ပြီးမှ data load လုပ်ရန်
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() { _isLoading = true; });

    // *** အဓိက ပြင်ဆင်မှု (၁) - AppLocalizations ကို context ရှိတဲ့နေရာမှာပဲ ခေါ်ပါ ***
    // ဒီ function ကို didChangeDependencies သို့မဟုတ် build method ကနေ ခေါ်ရပါမယ်။
    // အခုတော့ didChangeDependencies ကိုသုံးပါမယ်။
    final loc = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(currentMonth);

    double incomeThisMonth = 0;
    List<String> categoriesThisMonth = [loc.t('others')];
    final plansString = prefs.getString('all_plans');
    if (plansString != null) {
      final allPlans = json.decode(plansString) as Map<String, dynamic>;
      if (allPlans.containsKey(monthKey)) {
        final List<dynamic> currentMonthPlans = allPlans[monthKey];
        categoriesThisMonth.addAll(currentMonthPlans
            .map((plan) => plan['name'] as String)
            .toSet()
            .toList());
      }
    }

    final incomesString = prefs.getString('all_incomes');
    if (incomesString != null) {
      final allIncomes = json.decode(incomesString) as Map<String, dynamic>;
      if (allIncomes.containsKey(monthKey)) {
        final List<dynamic> currentMonthIncomes = allIncomes[monthKey];
        incomeThisMonth += currentMonthIncomes.fold(
            0.0, (sum, item) => sum + (item['amount'] as num));
      }
    }

    double spentThisMonth = 0;
    List<Map<String, dynamic>> allExpensesList = [];
    Map<String, double> categorySpending = {};
    final expensesString = prefs.getString('allExpenses');
    if (expensesString != null) {
      final allExpenses = json.decode(expensesString) as Map<String, dynamic>;
      allExpenses.forEach((dateString, expenses) {
        final date = DateTime.parse(dateString);
        final expenseList = List<Map<String, dynamic>>.from(expenses);
        for (var expense in expenseList) {
          allExpensesList.add({...expense, 'date': date});
        }
        if (date.month == currentMonth.month && date.year == currentMonth.year) {
          for (var expense in expenseList) {
            spentThisMonth += (expense['amount'] as num).toDouble();
            final category = expense['category'] as String;
            categorySpending[category] =
                (categorySpending[category] ?? 0) +
                    (expense['amount'] as num).toDouble();
          }
        }
      });
    }

    allExpensesList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    _recentTransactions = allExpensesList.take(3).toList();

    var sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topCategories = Map.fromEntries(sortedCategories.take(4));

    if (mounted) {
      setState(() {
        _totalIncome = incomeThisMonth;
        _totalSpent = spentThisMonth;
        _categories = categoriesThisMonth.toSet().toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense(DateTime date, String name, double amount, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = DateFormat('yyyy-MM-dd').format(date);
    final expensesString = prefs.getString('allExpenses');
    Map<String, dynamic> allExpenses = {};
    if (expensesString != null) {
      allExpenses = json.decode(expensesString);
    }
    List<dynamic> dailyExpenses = allExpenses[key] ?? [];
    dailyExpenses.add({'name': name, 'amount': amount, 'category': category});
    allExpenses[key] = dailyExpenses;
    await prefs.setString('allExpenses', json.encode(allExpenses));
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildMonthlySummaryCard(),
                  const SizedBox(height: 20),
                  _buildQuickActionsCard(),
                  const SizedBox(height: 20),
                  _buildRecentTransactionsCard(),
                  const SizedBox(height: 20),
                  if (_topCategories.isNotEmpty) _buildTopCategoriesCard(),
                  const SizedBox(height: 20),
                  _buildFinancialTipCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final loc = AppLocalizations.of(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final remaining = _totalIncome - _totalSpent;
    final progress = _totalIncome > 0 ? (_totalSpent / _totalIncome).clamp(0, 1) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('homeSummaryTitle', args: {'month': DateFormat.yMMMM(loc.locale.languageCode).format(DateTime.now())}),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(loc.t('homeIncome'), _totalIncome, Colors.green),
                _summaryItem(loc.t('homeSpent'), _totalSpent, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            Text(loc.t('homeRemaining'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text(
              NumberFormat.currency(symbol: '${currencyProvider.currencySymbol} ', decimalDigits: 0).format(remaining),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: remaining >= 0 ? Colors.blue : Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _summaryItem(String title, double amount, Color color) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          NumberFormat.currency(symbol: '${currencyProvider.currencySymbol} ', decimalDigits: 0).format(amount),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  Widget _buildQuickActionsCard() {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_card),
            label: Text(loc.t('homeAddExpense')),
            onPressed: () async {
              await showExpenseInputModal(context, DateTime.now(), _categories, _addExpense);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: Text(loc.t('homeViewReports')),
            onPressed: () => widget.onNavigateToTab(3),
             style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard() {
    final loc = AppLocalizations.of(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('homeRecentTransactions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_recentTransactions.isEmpty)
              Center(child: Text(loc.t('homeNoTransactions'), style: const TextStyle(color: Colors.grey))),
            ..._recentTransactions.map((tx) => ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                  title: Text(tx['name']),
                  subtitle: Text(DateFormat.yMMMd(loc.locale.languageCode).format(tx['date'])),
                  trailing: Text(
                    NumberFormat.currency(symbol: '${currencyProvider.currencySymbol} ', decimalDigits: 0).format(tx['amount']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesCard() {
    final loc = AppLocalizations.of(context);
    final List<Color> pieColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple
    ];
    int colorIndex = 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('homeTopCategories'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: PieChart(
                    PieChartData(
                      sections: _topCategories.entries.map((entry) {
                        final color = pieColors[colorIndex++ % pieColors.length];
                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: '',
                          radius: 40,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _topCategories.entries.map((entry) {
                      final color = pieColors[(_topCategories.keys.toList().indexOf(entry.key)) % pieColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, color: color),
                            const SizedBox(width: 8),
                            Text(entry.key),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTipCard() {
    final loc = AppLocalizations.of(context);
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                loc.t('homeFinancialTip'),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
