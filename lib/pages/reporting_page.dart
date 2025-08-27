import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';
import 'reports/monthly_report_view.dart';
import 'reports/weekly_report_view.dart';
// This import now gives us access to both the YearlyReportView and the CategorySummary class
import 'reports/yearly_report_view.dart'; 

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- RAW DATA STATE ---
  Map<DateTime, List<Map<String, dynamic>>> _allExpensesData = {};
  Map<DateTime, List<Map<String, dynamic>>> _allIncomesByDate = {};
  String? _allIncomesData;
  String? _allPlansData;

  // --- CALCULATED REPORT STATE ---
  // Weekly
  Map<String, double> _weeklyCategoryExpenses = {};
  double _currentWeekIncome = 0;
  double _previousWeekIncome = 0;
  double _previousWeekExpenses = 0;
  
  // Monthly
  Map<String, double> _monthlyCategoryExpenses = {};
  double _currentMonthIncome = 0;
  double _previousMonthIncome = 0;
  double _previousMonthExpenses = 0;

  // Yearly - Updated to hold the summary object with transaction counts
  Map<String, CategorySummary> _yearlyCategorySummaries = {};
  double _yearlyTotalIncome = 0;
  double _yearlyTotalExpense = 0;
  double _previousYearIncome = 0;
  double _previousYearExpenses = 0;
  
  // Planning
  Map<String, double> _plannedAmounts = {};
  Map<String, double> _actualAmounts = {};

  // --- UI STATE ---
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  // --- DATA LOADING & PROCESSING ---

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
    
    if (_allIncomesData != null) {
      final decoded = json.decode(_allIncomesData!) as Map<String, dynamic>;
      decoded.forEach((monthKey, incomes) {
        if (incomes is List && incomes.isNotEmpty) {
          final date = DateTime.parse('$monthKey-01');
          _allIncomesByDate[date] = List<Map<String, dynamic>>.from(incomes);
        }
      });
    }

    _recalculateAllReports();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  void _recalculateAllReports() {
    _calculateWeeklySummaryData();
    _calculateMonthlySummaryData();
    _calculateYearlySummaryData();
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

  // New method to get full details including transaction count
  Map<String, CategorySummary> _aggregateExpenseDetails(DateTime start, DateTime end) {
    Map<String, CategorySummary> categoryDetails = {};
    _allExpensesData.forEach((date, expenses) {
      final localDate = date.toLocal();
      if (!localDate.isBefore(start) && localDate.isBefore(end.add(const Duration(days: 1)))) {
        for (var expense in expenses) {
          final category = expense['category'] as String;
          final amount = (expense['amount'] as num).toDouble();
          
          final currentTotal = categoryDetails[category]?.totalAmount ?? 0;
          final currentCount = categoryDetails[category]?.transactionCount ?? 0;

          categoryDetails[category] = CategorySummary(
            totalAmount: currentTotal + amount,
            transactionCount: currentCount + 1,
          );
        }
      }
    });
    return categoryDetails;
  }
  
  double _getIncomeForPeriod(DateTime start, DateTime end) {
    double totalIncome = 0;
    _allIncomesByDate.forEach((date, incomes) {
       final localDate = date.toLocal();
      if (!localDate.isBefore(start) && localDate.isBefore(end.add(const Duration(days: 1)))) {
        for (var income in incomes) {
           totalIncome += (income['amount'] as num).toDouble();
        }
      }
    });
    return totalIncome;
  }

  void _calculateWeeklySummaryData() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    _weeklyCategoryExpenses = _aggregateExpenses(startOfWeek, endOfWeek);
    _currentWeekIncome = _getIncomeForPeriod(startOfWeek, endOfWeek);

    final startOfPrevWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfPrevWeek = startOfWeek.subtract(const Duration(days: 1));
    final prevWeekExpensesMap = _aggregateExpenses(startOfPrevWeek, endOfPrevWeek);
    _previousWeekExpenses = prevWeekExpensesMap.values.fold(0.0, (sum, item) => sum + item);
    _previousWeekIncome = _getIncomeForPeriod(startOfPrevWeek, endOfPrevWeek);
  }

  void _calculateMonthlySummaryData() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    _monthlyCategoryExpenses = _aggregateExpenses(startOfMonth, endOfMonth);
    _currentMonthIncome = _getIncomeForPeriod(startOfMonth, endOfMonth);

    final startOfPrevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    final endOfPrevMonth = DateTime(_selectedDate.year, _selectedDate.month, 0);
    final prevMonthExpensesMap = _aggregateExpenses(startOfPrevMonth, endOfPrevMonth);
    _previousMonthExpenses = prevMonthExpensesMap.values.fold(0.0, (sum, item) => sum + item);
    _previousMonthIncome = _getIncomeForPeriod(startOfPrevMonth, endOfPrevMonth);
  }

  void _calculateYearlySummaryData() {
    final startOfYear = DateTime(_selectedDate.year, 1, 1);
    final endOfYear = DateTime(_selectedDate.year, 12, 31);
    
    _yearlyCategorySummaries = _aggregateExpenseDetails(startOfYear, endOfYear);
    _yearlyTotalExpense = _yearlyCategorySummaries.values.fold(0.0, (sum, item) => sum + item.totalAmount);
    _yearlyTotalIncome = _getIncomeForPeriod(startOfYear, endOfYear);

    final startOfPrevYear = DateTime(_selectedDate.year - 1, 1, 1);
    final endOfPrevYear = DateTime(_selectedDate.year - 1, 12, 31);
    final prevYearExpensesMap = _aggregateExpenseDetails(startOfPrevYear, endOfPrevYear);
    _previousYearExpenses = prevYearExpensesMap.values.fold(0.0, (sum, item) => sum + item.totalAmount);
    _previousYearIncome = _getIncomeForPeriod(startOfPrevYear, endOfPrevYear);
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
        title: TabBar(
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
                WeeklyReportView(
                  selectedDate: _selectedDate,
                  weeklyCategoryExpenses: _weeklyCategoryExpenses,
                  currencySymbol: currencyProvider.currencySymbol,
                  currentWeekIncome: _currentWeekIncome,
                  previousWeekIncome: _previousWeekIncome,
                  previousWeekExpenses: _previousWeekExpenses,
                  onPrevious: () => setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    _recalculateAllReports();
                  }),
                  onNext: () => setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                    _recalculateAllReports();
                  }),
                ),
                MonthlyReportView(
                  selectedDate: _selectedDate,
                  monthlyCategoryExpenses: _monthlyCategoryExpenses,
                  plannedAmounts: _plannedAmounts,
                  actualAmounts: _actualAmounts,
                  currencySymbol: currencyProvider.currencySymbol,
                  currentMonthIncome: _currentMonthIncome,
                  previousMonthIncome: _previousMonthIncome,
                  previousMonthExpenses: _previousMonthExpenses,
                  onPrevious: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                    _recalculateAllReports();
                  }),
                   onNext: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                    _recalculateAllReports();
                  }),
                ),
                YearlyReportView(
                  selectedDate: _selectedDate,
                  yearlyTotalIncome: _yearlyTotalIncome,
                  yearlyTotalExpense: _yearlyTotalExpense,
                  yearlyCategorySummaries: _yearlyCategorySummaries,
                  currencySymbol: currencyProvider.currencySymbol,
                  previousYearIncome: _previousYearIncome,
                  previousYearExpenses: _previousYearExpenses,
                  onPrevious: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year - 1);
                    _recalculateAllReports();
                  }),
                  onNext: () => setState(() {
                    _selectedDate = DateTime(_selectedDate.year + 1);
                    _recalculateAllReports();
                  }),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}