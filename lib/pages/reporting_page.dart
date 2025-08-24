import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<DateTime, List<Map<String, dynamic>>> _allExpensesData = {};
  String? _allIncomesData;
  String? _allPlansData;

  Map<String, double> _weeklyCategoryExpenses = {};
  Map<String, double> _monthlyCategoryExpenses = {};
  Map<String, double> _yearlyCategoryExpenses = {};
  double _yearlyTotalIncome = 0;
  double _yearlyTotalExpense = 0;
  Map<String, double> _plannedAmounts = {};
  Map<String, double> _actualAmounts = {};

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  final List<Color> _pieChartColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.indigo, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; });

    final prefs = await SharedPreferences.getInstance();
    final expensesString = prefs.getString('allExpenses');
    _allPlansData = prefs.getString('all_plans');
    _allIncomesData = prefs.getString('all_incomes');

    if (expensesString != null) {
      final decoded = json.decode(expensesString) as Map<String, dynamic>;
      _allExpensesData = decoded.map((key, value) => MapEntry(
          DateTime.parse(key), List<Map<String, dynamic>>.from(value)));
    }

    _recalculateAllReports();
    setState(() { _isLoading = false; });
  }

  void _recalculateAllReports() {
    _calculateWeeklyExpenses();
    _calculateMonthlyExpenses();
    _calculateYearlyData();
    _calculatePlanningVsActual();
  }
  
  Map<String, double> _aggregateExpenses(DateTime start, DateTime end) {
    Map<String, double> categoryExpenses = {};
    _allExpensesData.forEach((date, expenses) {
      final localDate = date.toLocal();
      if (!localDate.isBefore(start) && localDate.isBefore(end.add(const Duration(days: 1)))) {
        for (var expense in expenses) {
          final category = expense['category'] as String;
          final amount = (expense['amount'] as num).toDouble();
          categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
        }
      }
    });
    return categoryExpenses;
  }

  void _calculateWeeklyExpenses() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _weeklyCategoryExpenses = _aggregateExpenses(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day), 
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day)
    );
  }

  void _calculateMonthlyExpenses() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    _monthlyCategoryExpenses = _aggregateExpenses(startOfMonth, endOfMonth);
  }

  void _calculateYearlyData() {
    final startOfYear = DateTime(_selectedDate.year, 1, 1);
    final endOfYear = DateTime(_selectedDate.year, 12, 31);
    _yearlyCategoryExpenses = _aggregateExpenses(startOfYear, endOfYear);
    _yearlyTotalExpense = _yearlyCategoryExpenses.values.fold(0.0, (sum, item) => sum + item);

    double totalIncome = 0;
    if (_allIncomesData != null) {
      final allIncomes = json.decode(_allIncomesData!) as Map<String, dynamic>;
      allIncomes.forEach((monthKey, incomes) {
        if (monthKey.startsWith('${_selectedDate.year}')) {
          totalIncome += (incomes as List).fold(0.0, (sum, item) => sum + (item['amount'] as num));
        }
      });
    }
    _yearlyTotalIncome = totalIncome;
  }

  void _calculatePlanningVsActual() {
    final monthKey = DateFormat('yyyy-MM').format(_selectedDate);
    
    Map<String, double> planned = {};
    if (_allPlansData != null) {
      final allPlans = json.decode(_allPlansData!) as Map<String, dynamic>;
      if (allPlans.containsKey(monthKey)) {
        for (var plan in allPlans[monthKey]) {
          planned[plan['name']] = (plan['amount'] as num).toDouble();
        }
      }
    }
    _plannedAmounts = planned;

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    _actualAmounts = _aggregateExpenses(startOfMonth, endOfMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
            Tab(text: "Yearly"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyReportView(),
                _buildMonthlyReportView(),
                _buildYearlyReportView(),
              ],
            ),
    );
  }
  
  Widget _buildWeeklyReportView() {
    final dayOfWeek = _selectedDate.weekday == 7 ? 0 : _selectedDate.weekday;
    final startOfWeek = _selectedDate.subtract(Duration(days: dayOfWeek));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    String dateRangeDisplay = '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.yMMMd().format(endOfWeek)}';
    
    final totalWeeklySpend = _weeklyCategoryExpenses.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        _buildDateNavigator(
          display: dateRangeDisplay,
          onPrevious: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              _calculateWeeklyExpenses();
            });
          },
          onNext: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 7));
              _calculateWeeklyExpenses();
            });
          },
        ),
        Expanded(
          child: _buildPieChartSection(
            _weeklyCategoryExpenses,
            "Weekly Expenses",
            totalWeeklySpend
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportView() {
    final totalMonthlySpend = _monthlyCategoryExpenses.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.yMMMM().format(_selectedDate),
          onPrevious: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
              _calculateMonthlyExpenses();
              _calculatePlanningVsActual();
            });
          },
          onNext: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
              _calculateMonthlyExpenses();
              _calculatePlanningVsActual();
            });
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildTotalExpensesCard("Total Monthly Spend", totalMonthlySpend),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text("Monthly Expenses by Category", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 20),
                       SizedBox(height: 250, child: _buildPieChart(_monthlyCategoryExpenses)),
                       _buildLegend(_monthlyCategoryExpenses),
                    ],
                  ),
                ),
              ),
              const Divider(height: 40),
              // *** အဓိက ပြင်ဆင်မှု (၁) - Bar Chart Report ကို Card နဲ့ စုစည်းပြီး Legend ထည့်သွင်းခြင်း ***
              Card(
                 elevation: 2,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                 child: Padding(
                  padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("Planning vs Actual Spending", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       _buildBarChartLegend(), // Legend ကို ဤနေရာတွင်ထည့်ပါ
                       const SizedBox(height: 20),
                       SizedBox(height: 300, child: _buildBarChart()),
                     ],
                   ),
                 ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Yearly Report View
  Widget _buildYearlyReportView() {
    // *** အဓိက ပြင်ဆင်မှု- Yearly expenses များကို ကြီးစဉ်ငယ်လိုက် sorting လုပ်ခြင်း ***
    // 1. Map entries တွေကို List အဖြစ်ပြောင်းပါ
    final sortedYearlyExpenses = _yearlyCategoryExpenses.entries.toList();

    // 2. List ကို value (ကုန်ကျငွေ) အများအနည်းအလိုက် ကြီးစဉ်ငယ်လိုက် စီပါ
    sortedYearlyExpenses.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.y().format(_selectedDate),
          onPrevious: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, 1);
              _calculateYearlyData();
            });
          },
          onNext: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, 1);
              _calculateYearlyData();
            });
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildSummaryCard("Total Income", _yearlyTotalIncome, Colors.green),
              _buildSummaryCard("Total Expenses", _yearlyTotalExpense, Colors.red),
              const Divider(height: 40),
              const Text("Expenses by Category (Yearly)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (sortedYearlyExpenses.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No yearly expense data.")))
              else
                // 3. Sorting လုပ်ပြီးသား list အသစ်ကို အသုံးပြုပြီး Widget တွေ တည်ဆောက်ပါ
                ...sortedYearlyExpenses.map((entry) => Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                          NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator({required String display, required VoidCallback onPrevious, required VoidCallback onNext}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevious),
          Text(display, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(Map<String, double> data, String title, double total) {
    if (data.isEmpty) {
      return Center(child: Text("No data for this period.", style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildTotalExpensesCard("Total Spend", total),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(height: 250, child: _buildPieChart(data)),
                const SizedBox(height: 20),
                _buildLegend(data),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
Widget _buildTotalExpensesCard(String title, double total) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // *** အဓိက ပြင်ဆင်မှု ***
        // Row ထဲက widget တွေကို Expanded နဲ့ ထိန်းချုပ်လိုက်ပါပြီ
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween, ကို ဖယ်ရှားလိုက်ပါ
          children: [
            // Title Text ကို Expanded ဖြင့် ထုပ်ပိုးလိုက်ပါ
            // ဒါမှ သူက ကျန်တဲ့နေရာကို အလိုအလျောက် ယူသွားပါလိမ့်မယ်
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            // Amount Text ကတော့ သူ့နေရာသူ ပုံမှန်အတိုင်း ရှိနေပါမယ်
            Text(
              NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(total),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
   Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) return const Center(child: Text("No expenses"));
    
    int colorIndex = 0;
    final totalValue = data.values.fold(0.0, (sum, item) => sum + item);

    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final color = _pieChartColors[colorIndex++ % _pieChartColors.length];
          final percentage = totalValue > 0 ? (entry.value / totalValue) * 100 : 0;
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 100,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data) {
    int colorIndex = 0;
    return Column(
      children: data.entries.map((entry) {
        final color = _pieChartColors[colorIndex++ % _pieChartColors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 14))),
              Text(
                NumberFormat.currency(symbol: ' MMK', decimalDigits: 0).format(entry.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // *** အသစ်ထပ်တိုး - Bar Chart အတွက် Legend Widget ***
  Widget _buildBarChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(width: 16, height: 16, color: Colors.blue.shade300),
            const SizedBox(width: 8),
            const Text('Planned'),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Container(width: 16, height: 16, color: Colors.red.shade300),
            const SizedBox(width: 8),
            const Text('Actual'),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final allCategories = {..._plannedAmounts, ..._actualAmounts}.keys.toList();
    if (allCategories.isEmpty) return const Center(child: Text("No planning or actual data"));

    double maxY = 0;
    for (var category in allCategories) {
        final planned = _plannedAmounts[category] ?? 0;
        final actual = _actualAmounts[category] ?? 0;
        if (planned > maxY) maxY = planned;
        if (actual > maxY) maxY = actual;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1000 : maxY * 1.2,
        barGroups: List.generate(allCategories.length, (index) {
          final category = allCategories[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: _plannedAmounts[category] ?? 0, color: Colors.blue.shade300, width: 15, borderRadius: BorderRadius.zero),
              BarChartRodData(toY: _actualAmounts[category] ?? 0, color: Colors.red.shade300, width: 15, borderRadius: BorderRadius.zero),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < allCategories.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4.0,
                    child: Text(allCategories[index], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
             getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10)),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = rodIndex == 0 ? 'Planned' : 'Actual';
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(rod.toY),
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(
              NumberFormat.currency(symbol: 'MMK ', decimalDigits: 0).format(amount),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}