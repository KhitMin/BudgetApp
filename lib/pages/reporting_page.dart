import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

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
    if (!mounted) return;
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
    if (mounted) {
      setState(() { _isLoading = false; });
    }
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
    final loc = AppLocalizations.of(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('reportTitle')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.t('reportWeekly')),
            Tab(text: loc.t('reportMonthly')),
            Tab(text: loc.t('reportYearly')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyReportView(currencyProvider.currencySymbol),
                _buildMonthlyReportView(currencyProvider.currencySymbol),
                _buildYearlyReportView(currencyProvider.currencySymbol),
              ],
            ),
    );
  }
  
  Widget _buildWeeklyReportView(String currencySymbol) {
    final loc = AppLocalizations.of(context);
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    String dateRangeDisplay = '${DateFormat.MMMd(loc.locale.languageCode).format(startOfWeek)} - ${DateFormat.yMMMd(loc.locale.languageCode).format(endOfWeek)}';
    final totalWeeklySpend = _weeklyCategoryExpenses.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        _buildDateNavigator(
          display: dateRangeDisplay,
          onPrevious: () => setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 7)); _calculateWeeklyExpenses(); }),
          onNext: () => setState(() { _selectedDate = _selectedDate.add(const Duration(days: 7)); _calculateWeeklyExpenses(); }),
        ),
        Expanded(
          child: _buildPieChartSection(
            data: _weeklyCategoryExpenses,
            title: loc.t('reportWeekly'),
            total: totalWeeklySpend,
            currencySymbol: currencySymbol,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportView(String currencySymbol) {
    final loc = AppLocalizations.of(context);
    final totalMonthlySpend = _monthlyCategoryExpenses.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.yMMMM(loc.locale.languageCode).format(_selectedDate),
          onPrevious: () => setState(() { _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1); _recalculateAllReports(); }),
          onNext: () => setState(() { _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1); _recalculateAllReports(); }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildTotalExpensesCard(loc.t('reportTotalSpend'), totalMonthlySpend, currencySymbol),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(loc.t('reportMonthlyExpensesByCategory'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 20),
                       SizedBox(height: 250, child: _buildPieChart(_monthlyCategoryExpenses)),
                       _buildLegend(_monthlyCategoryExpenses, currencySymbol),
                    ],
                  ),
                ),
              ),
              const Divider(height: 40),
              Card(
                 elevation: 2,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                 child: Padding(
                  padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(loc.t('reportPlanningVsActual'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       _buildBarChartLegend(),
                       const SizedBox(height: 20),
                       SizedBox(height: 300, child: _buildBarChart(currencySymbol)),
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

  Widget _buildYearlyReportView(String currencySymbol) {
    final loc = AppLocalizations.of(context);
    final sortedYearlyExpenses = _yearlyCategoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.y(loc.locale.languageCode).format(_selectedDate),
          onPrevious: () => setState(() { _selectedDate = DateTime(_selectedDate.year - 1); _calculateYearlyData(); }),
          onNext: () => setState(() { _selectedDate = DateTime(_selectedDate.year + 1); _calculateYearlyData(); }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildSummaryCard(loc.t('reportYearlyIncome'), _yearlyTotalIncome, Colors.green, currencySymbol),
              _buildSummaryCard(loc.t('reportYearlyExpenses'), _yearlyTotalExpense, Colors.red, currencySymbol),
              const Divider(height: 40),
              Text(loc.t('reportYearlyExpensesByCategory'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (sortedYearlyExpenses.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(loc.t('reportNoData'))))
              else
                ...sortedYearlyExpenses.map((entry) => Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                          NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(entry.value),
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

  Widget _buildPieChartSection({required Map<String, double> data, required String title, required double total, required String currencySymbol}) {
    final loc = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(child: Text(loc.t('reportNoData'), style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildTotalExpensesCard(loc.t('reportTotalSpend'), total, currencySymbol),
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
                _buildLegend(data, currencySymbol),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTotalExpensesCard(String title, double total, String currencySymbol) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
            Text(
              NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(total),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
  
   Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) return Center(child: Text(AppLocalizations.of(context).t('reportNoData')));
    int colorIndex = 0;
    final totalValue = data.values.fold(0.0, (sum, item) => sum + item);
    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final color = _pieChartColors[colorIndex++ % _pieChartColors.length];
          final percentage = totalValue > 0 ? (entry.value / totalValue) * 100 : 0;
          return PieChartSectionData(
            color: color, value: entry.value, title: '${percentage.toStringAsFixed(0)}%', radius: 100,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2, centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data, String currencySymbol) {
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
                NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(entry.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChartLegend() {
    final loc = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [Container(width: 16, height: 16, color: Colors.blue.shade300), const SizedBox(width: 8), Text(loc.t('reportPlanned'))]),
        const SizedBox(width: 24),
        Row(children: [Container(width: 16, height: 16, color: Colors.red.shade300), const SizedBox(width: 8), Text(loc.t('reportActual'))]),
      ],
    );
  }

  Widget _buildBarChart(String currencySymbol) {
    final loc = AppLocalizations.of(context);
    final allCategories = {..._plannedAmounts, ..._actualAmounts}.keys.toList();
    if (allCategories.isEmpty) return Center(child: Text(loc.t('reportNoData')));

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
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
            final index = value.toInt();
            if (index >= 0 && index < allCategories.length) {
              return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(allCategories[index], style: const TextStyle(fontSize: 10)));
            }
            return const Text('');
          }, reservedSize: 38)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = rodIndex == 0 ? loc.t('reportPlanned') : loc.t('reportActual');
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(rod.toY),
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

  Widget _buildSummaryCard(String title, double amount, Color color, String currencySymbol) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(
              NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 0).format(amount),
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
