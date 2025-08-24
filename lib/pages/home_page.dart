import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

// Refactor လုပ်ထားတဲ့ modal ကို import လုပ်ပါ
import 'widgets/expense_input_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Data variables
  double _totalIncome = 0.0;
  double _totalSpent = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _topCategories = {};
  List<String> _categories = ['Others'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // SharedPreferences ကနေ data အားလုံးကို load လုပ်ပြီး တွက်ချက်မယ့် মূল function
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final currentMonth = DateTime.now();
    final monthKey = DateFormat('yyyy-MM').format(currentMonth);

    // 1. Load Incomes and Plans
    double incomeThisMonth = 0;
    List<String> categoriesThisMonth = ['Others'];
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
      final allIncomes =
          json.decode(incomesString) as Map<String, dynamic>;
      if (allIncomes.containsKey(monthKey)) {
        final List<dynamic> currentMonthIncomes = allIncomes[monthKey];
        incomeThisMonth += currentMonthIncomes.fold(
            0.0, (sum, item) => sum + (item['amount'] as num));
      }
    }

    // 2. Load Expenses
    double spentThisMonth = 0;
    List<Map<String, dynamic>> allExpensesList = [];
    Map<String, double> categorySpending = {};

    final expensesString = prefs.getString('allExpenses');
    if (expensesString != null) {
      final allExpenses =
          json.decode(expensesString) as Map<String, dynamic>;
      allExpenses.forEach((dateString, expenses) {
        final date = DateTime.parse(dateString);
        final expenseList = List<Map<String, dynamic>>.from(expenses);

        // Add date to each expense for sorting
        for (var expense in expenseList) {
          allExpensesList.add({...expense, 'date': date});
        }

        if (date.month == currentMonth.month &&
            date.year == currentMonth.year) {
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

    // 3. Sort and get recent transactions
    allExpensesList.sort((a, b) => (b['date'] as DateTime)
        .compareTo(a['date'] as DateTime));
    _recentTransactions = allExpensesList.take(3).toList();

    // 4. Sort and get top categories
    var sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topCategories = Map.fromEntries(sortedCategories.take(4));

    // 5. Update state
    setState(() {
      _totalIncome = incomeThisMonth;
      _totalSpent = spentThisMonth;
      _categories = categoriesThisMonth.toSet().toList();
      _isLoading = false;
    });
  }

  // Expense အသစ်ထည့်ပြီး data သိမ်းဆည်းရန် function
  Future<void> _addExpense(DateTime date, String name, double amount, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = DateFormat('yyyy-MM-dd').format(date);

    final expensesString = prefs.getString('allExpenses');
    Map<String, dynamic> allExpenses = {};
    if (expensesString != null) {
      allExpenses = json.decode(expensesString);
    }

    List<dynamic> dailyExpenses = allExpenses[key] ?? [];
    dailyExpenses.add({
      'name': name,
      'amount': amount,
      'category': category,
    });
    allExpenses[key] = dailyExpenses;
    
    await prefs.setString('allExpenses', json.encode(allExpenses));
    _loadDashboardData(); // Refresh dashboard
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

  // 1. Monthly Summary Card
// 1. Monthly Summary Card
  Widget _buildMonthlySummaryCard() {
    // *** ဤနေရာတွင် progress variable ကို ကြေညာရန် ကျန်နေခဲ့ခြင်းဖြစ်နိုင်သည် ***
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
              'Summary for ${DateFormat.yMMMM().format(DateTime.now())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem('Income', _totalIncome, Colors.green),
                _summaryItem('Spent', _totalSpent, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Remaining', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text(
              '${NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(remaining)}',
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
                value: progress.toDouble(), // အခု ဒီနေရာမှာ error မရှိတော့ပါ
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(amount),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
  
  // 2. Quick Actions Card
  Widget _buildQuickActionsCard() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_card),
            label: const Text('Add Expense'),
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
            label: const Text('View Reports'),
            onPressed: () {
              // Reporting tab ကိုသွားရန် (main.dart မှာ handle လုပ်ရန်လို)
              // This requires a way to change tabs, e.g., using a Provider or callback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporting feature coming soon!')),
              );
            },
             style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Recent Transactions Card
  Widget _buildRecentTransactionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_recentTransactions.isEmpty)
              const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey))),
            ..._recentTransactions.map((tx) => ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                  title: Text(tx['name']),
                  subtitle: Text(DateFormat.yMMMd().format(tx['date'])),
                  trailing: Text(
                    '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(tx['amount'])} MMK',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // 4. Top Spending Categories Card
  Widget _buildTopCategoriesCard() {
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
            const Text(
              'Top Spending Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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

  // 5. Financial Tip Card
  Widget _buildFinancialTipCard() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Tip: Review your monthly subscriptions to find potential savings!',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}