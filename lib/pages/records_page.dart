import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

// A simple model to hold combined transaction data
class Transaction {
  final bool isExpense;
  final String name;
  final double amount;
  final String category;
  final DateTime date;

  Transaction({
    required this.isExpense,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
  });
}

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String _transactionType = 'All'; // 'All', 'Income', 'Expenses'
  String? _selectedCategory;

  List<String> _allCategories = [];
  bool _sortAscending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    List<Transaction> loadedTransactions = [];
    Set<String> categories = {};

    // Load Incomes from the correct key: 'planned_incomes'
    final incomesString = prefs.getString('planned_incomes');
    if (incomesString != null) {
      final Map<String, dynamic> allIncomes = json.decode(incomesString);
      allIncomes.forEach((_, monthIncomes) {
        for (var income in monthIncomes) {
          // Handle new and old category formats
          final categoryData = income['category'];
          final categoryName = categoryData is Map
              ? categoryData['name']
              : categoryData.toString();

          loadedTransactions.add(
            Transaction(
              isExpense: false,
              name: income['name'],
              amount: (income['amount'] as num).toDouble(),
              category: categoryName,
              date: DateTime.parse(income['date']),
            ),
          );
          categories.add(categoryName);
        }
      });
    }

    // Load Expenses from the correct key: 'planned_expenses'
    final expensesString = prefs.getString('planned_expenses');
    if (expensesString != null) {
      final Map<String, dynamic> allExpenses = json.decode(expensesString);
      allExpenses.forEach((_, monthExpenses) {
        for (var expense in monthExpenses) {
          // Handle new and old category formats
          final categoryData = expense['category'];
          final categoryName = categoryData is Map
              ? categoryData['name']
              : categoryData.toString();

          loadedTransactions.add(
            Transaction(
              isExpense: true,
              name: expense['name'],
              amount: (expense['amount'] as num).toDouble(),
              category: categoryName,
              date: DateTime.parse(expense['date']),
            ),
          );
          categories.add(categoryName);
        }
      });
    }

    setState(() {
      _allTransactions = loadedTransactions;
      _allCategories = categories.toList()..sort();
      _isLoading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Date Range Filter
    if (_startDate != null) {
      filtered = filtered.where((t) => !t.date.isBefore(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Transaction Type Filter
    if (_transactionType == 'Income') {
      filtered = filtered.where((t) => !t.isExpense).toList();
    } else if (_transactionType == 'Expenses') {
      filtered = filtered.where((t) => t.isExpense).toList();
    }

    // Category Filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Sorting
    filtered.sort(
      (a, b) =>
          _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
    );

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterSection(context),
                _buildResultsHeader(context),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionTile(
                        _filteredTransactions[index],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range
          Text(loc.t('dateRange'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDatePickerField(context, isStart: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePickerField(context, isStart: false)),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Type
          Text(loc.t('transactionType'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildTypeSwitcher(context),
          const SizedBox(height: 16),

          // Category
          Text(loc.t('category'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildCategoryDropdown(context),
          const SizedBox(height: 24),

          // Apply Button
          ElevatedButton.icon(
            icon: const Icon(Icons.filter_list),
            label: Text(loc.t('applyFilters')),
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context, {required bool isStart}) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = isStart ? _startDate : _endDate;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() {
            if (isStart)
              _startDate = picked;
            else
              _endDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? DateFormat.yMd(loc.locale.languageCode).format(date)
                  : (isStart ? loc.t('startDate') : loc.t('endDate')),
              style: theme.textTheme.bodyLarge,
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: ToggleButtons(
        isSelected: [
          _transactionType == 'All',
          _transactionType == 'Income',
          _transactionType == 'Expenses',
        ],
        onPressed: (index) {
          setState(() {
            if (index == 0)
              _transactionType = 'All';
            else if (index == 1)
              _transactionType = 'Income';
            else
              _transactionType = 'Expenses';
          });
        },
        borderRadius: BorderRadius.circular(8.0),
        selectedColor: theme.colorScheme.onPrimary,
        color: theme.colorScheme.onSurfaceVariant,
        fillColor: theme.colorScheme.primary,
        constraints: BoxConstraints(
          minHeight: 40.0,
          minWidth: (MediaQuery.of(context).size.width - 48) / 3,
        ),
        children: [
          Text(loc.t('all')),
          Text(loc.t('income')),
          Text(loc.t('expenses')),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      hint: Text(loc.t('allCategories')),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(loc.t('allCategories')),
        ),
        ..._allCategories.map(
          (category) =>
              DropdownMenuItem(value: category, child: Text(category)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            loc.t(
              'transactionsFound',
              args: {'count': _filteredTransactions.length.toString()},
            ),
            style: theme.textTheme.bodyLarge,
          ),
          TextButton.icon(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
            label: Text(loc.t('sortBy')),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final currencySymbol = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    ).currencySymbol;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(
          transaction.isExpense
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: transaction.isExpense ? Colors.redAccent : Colors.green,
        ),
        title: Text(transaction.name),
        subtitle: Text(transaction.category),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NumberFormat.currency(
                symbol: currencySymbol,
              ).format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.isExpense ? Colors.redAccent : Colors.green,
              ),
            ),
            Text(
              DateFormat.yMd().format(transaction.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
