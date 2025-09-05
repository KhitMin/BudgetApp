import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'widgets/expense_input_modal.dart';
import '../providers/currency_provider.dart';

// A simple model to hold summary data
class PeriodSummary {
  final double income;
  final double expense;
  PeriodSummary({this.income = 0.0, this.expense = 0.0});
}

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, List<Map<String, dynamic>>> _allExpenses = {};
  Map<String, List<Map<String, dynamic>>> _allIncomes = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // --- DATA LOADING AND SAVING ---

  void _loadData() async {
    await _loadAllExpenses();
    await _loadAllIncomes();
    await _loadCategories();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('allExpenses');
    if (dataString != null) {
      final decodedData = json.decode(dataString) as Map<String, dynamic>;
      _allExpenses = decodedData.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)));
    }
  }

  Future<void> _loadAllIncomes() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('allIncomes');
    if (dataString != null) {
      final decodedData = json.decode(dataString) as Map<String, dynamic>;
      _allIncomes = decodedData.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)));
    }
  }

  Future<void> _saveExpensesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allExpenses', json.encode(_allExpenses));
  }
  
  Future<void> _saveIncomesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allIncomes', json.encode(_allIncomes));
  }

  // --- BALANCE HANDLING ---

  Future<void> _updateCurrentBalance(double amount, bool isExpense) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBalance = prefs.getDouble('current_balance') ?? 0.0;
    final newBalance = isExpense ? currentBalance - amount : currentBalance + amount;
    await prefs.setDouble('current_balance', newBalance);
  }

  // --- TRANSACTION HANDLING ---
  
  Future<void> _handleSaveTransaction(bool isExpense, DateTime date, String name, double amount, String category, TimeOfDay time) async {
    final transaction = {'name': name, 'amount': amount, 'category': category, 'time': '${time.hour}:${time.minute}'};
    final key = DateFormat('yyyy-MM-dd').format(date);
    
    if (isExpense) {
      final dailyExpenses = _allExpenses[key] ?? [];
      dailyExpenses.add(transaction);
      _allExpenses[key] = dailyExpenses;
      await _saveExpensesToPrefs();
      await _updateCurrentBalance(amount, true); // Update balance for expense
    } else {
      final dailyIncomes = _allIncomes[key] ?? [];
      dailyIncomes.add(transaction);
      _allIncomes[key] = dailyIncomes;
      await _saveIncomesToPrefs();
      await _updateCurrentBalance(amount, false); // Update balance for income
    }
    setState(() {});
  }

  Future<void> _updateTransaction(bool isExpense, DateTime date, int index, String name, double amount, String category, TimeOfDay time) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    
    if (isExpense) {
      final dailyExpenses = _allExpenses[key] ?? [];
      final oldAmount = dailyExpenses[index]['amount'] as double;
      
      dailyExpenses[index] = {'name': name, 'amount': amount, 'category': category, 'time': '${time.hour}:${time.minute}'};
      _allExpenses[key] = dailyExpenses;
      await _saveExpensesToPrefs();
      
      await _updateCurrentBalance(oldAmount, false); // Add back old amount
      await _updateCurrentBalance(amount, true);    // Subtract new amount
    } else {
      final dailyIncomes = _allIncomes[key] ?? [];
      final oldAmount = dailyIncomes[index]['amount'] as double;
      
      dailyIncomes[index] = {'name': name, 'amount': amount, 'category': category, 'time': '${time.hour}:${time.minute}'};
      _allIncomes[key] = dailyIncomes;
      await _saveIncomesToPrefs();
      
      await _updateCurrentBalance(oldAmount, true);  // Subtract old amount
      await _updateCurrentBalance(amount, false);   // Add new amount
    }
    
    setState(() {});
  }

  Future<void> _deleteTransaction(bool isExpense, DateTime date, int index) async {
    final key = DateFormat('yyyy-MM-dd').format(date);
    
    if (isExpense) {
      final dailyExpenses = _allExpenses[key] ?? [];
      if (index < 0 || index >= dailyExpenses.length) {
        print('Invalid expense index: $index, list length: ${dailyExpenses.length}');
        return;
      }
      
      final deletedAmount = dailyExpenses[index]['amount'] as double;
      dailyExpenses.removeAt(index);
      
      if (dailyExpenses.isEmpty) {
        _allExpenses.remove(key);
      } else {
        _allExpenses[key] = dailyExpenses;
      }
      await _saveExpensesToPrefs();
      await _updateCurrentBalance(deletedAmount, false); // Add back the deleted amount
    } else {
      final dailyIncomes = _allIncomes[key] ?? [];
      if (index < 0 || index >= dailyIncomes.length) {
        print('Invalid income index: $index, list length: ${dailyIncomes.length}');
        return;
      }
      
      final deletedAmount = dailyIncomes[index]['amount'] as double;
      dailyIncomes.removeAt(index);
      
      if (dailyIncomes.isEmpty) {
        _allIncomes.remove(key);
      } else {
        _allIncomes[key] = dailyIncomes;
      }
      await _saveIncomesToPrefs();
      await _updateCurrentBalance(deletedAmount, true); // Subtract the deleted amount
    }
    
    setState(() {});
  }
  
  List<Map<String, dynamic>> _getCombinedDailyTransactions(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    
    final expenses = _allExpenses[key]?.map((e) => {...e, 'type': 'expense'}).toList() ?? [];
    final incomes = _allIncomes[key]?.map((i) => {...i, 'type': 'income'}).toList() ?? [];
    
    final combined = [...expenses, ...incomes];
    combined.sort((a, b) {
      final timeA = a['time'] as String;
      final timeB = b['time'] as String;
      return timeA.compareTo(timeB);
    });
    return combined;
  }
  
  Future<void> _loadCategories() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    final plansString = prefs.getString('all_plans');
    final currentMonthKey = DateFormat('yyyy-MM').format(_focusedDay);
    List<String> loadedCategories = [];

    if (plansString != null) {
      final allPlans = json.decode(plansString) as Map<String, dynamic>;
      if (allPlans.containsKey(currentMonthKey)) {
        final List<dynamic> currentMonthPlans = allPlans[currentMonthKey];
        loadedCategories = currentMonthPlans.map((plan) => plan['name'] as String).toList();
      }
    }
    final uniqueCategories = {...loadedCategories, loc.t('others')}.toList();

    if (mounted) {
      setState(() {
        _categories = uniqueCategories;
      });
    }
  }

  // --- CALCULATION FUNCTIONS (TOTALS) ---

  double _sumTransactions(List<Map<String, dynamic>>? transactions) {
    if (transactions == null) return 0.0;
    double total = 0.0;
    for (final transaction in transactions) {
      total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  PeriodSummary _calculateWeeklyTotals(DateTime focusedDay) {
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;
    final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    _allIncomes.forEach((dateString, incomes) {
      try {
        final date = DateTime.parse(dateString);
        if (!date.isBefore(startOfWeek) && !date.isAfter(endOfWeek)) {
          incomeTotal += _sumTransactions(incomes);
        }
      } catch (e) {/* ignore */}
    });
    _allExpenses.forEach((dateString, expenses) {
      try {
        final date = DateTime.parse(dateString);
        if (!date.isBefore(startOfWeek) && !date.isAfter(endOfWeek)) {
          expenseTotal += _sumTransactions(expenses);
        }
      } catch (e) {/* ignore */}
    });
    return PeriodSummary(income: incomeTotal, expense: expenseTotal);
  }

  PeriodSummary _calculateMonthlyTotals(DateTime focusedDay) {
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;
    
    _allIncomes.forEach((dateString, incomes) {
      try {
        final date = DateTime.parse(dateString);
        if (date.month == focusedDay.month && date.year == focusedDay.year) {
          incomeTotal += _sumTransactions(incomes);
        }
      } catch (e) {/* ignore */}
    });
    _allExpenses.forEach((dateString, expenses) {
      try {
        final date = DateTime.parse(dateString);
        if (date.month == focusedDay.month && date.year == focusedDay.year) {
          expenseTotal += _sumTransactions(expenses);
        }
      } catch (e) {/* ignore */}
    });
    return PeriodSummary(income: incomeTotal, expense: expenseTotal);
  }
  
  double _calculateDailyBalanceForMarker(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final expenses = _sumTransactions(_allExpenses[key]);
    final incomes = _sumTransactions(_allIncomes[key]);
    return incomes - expenses; // Positive means we earned more than spent
  }

  // --- UI BUILDER METHODS ---

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final dailyTransactions = _selectedDay != null ? _getCombinedDailyTransactions(_selectedDay!) : [];
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryCards(),
            _buildTableCalendar(),
            const SizedBox(height: 8.0),
            if (_selectedDay == null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(loc.t('budgetSelectDayPrompt'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor)),
                  ),
                ),
              )
            else
              Expanded(
                child: dailyTransactions.isEmpty
                    ? Center(child: Text(loc.t('budgetNoTransactionsForDay')))
                    : ListView.builder(
                        itemCount: dailyTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = dailyTransactions[index];
                          final isExpense = transaction['type'] == 'expense';
                          return _buildTransactionTile(transaction, index, isExpense);
                        },
                      ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedDay != null) {
            await showExpenseInputModal(context, _selectedDay!, _handleSaveTransaction);
          }
        },
        tooltip: loc.t('budgetAddTransactionTooltip'),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    final weekTotals = _calculateWeeklyTotals(_focusedDay);
    final monthTotals = _calculateMonthlyTotals(_focusedDay);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _summaryCardItem(loc.t('thisWeek'), weekTotals)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCardItem(loc.t('thisMonth'), monthTotals)),
        ],
      ),
    );
  }

  Widget _summaryCardItem(String title, PeriodSummary summary) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final currencySymbol = currencyProvider.currencySymbol;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          _buildSummaryLine(
            value: summary.income,
            currencySymbol: currencySymbol,
            color: Colors.green.shade500,
            isIncome: true,
          ),
          const SizedBox(height: 4),
           _buildSummaryLine(
            value: summary.expense,
            currencySymbol: currencySymbol,
            color: Colors.red.shade500,
            isIncome: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine({required double value, required String currencySymbol, required Color color, required bool isIncome}) {
    final sign = isIncome ? '+' : '-';
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '$sign${NumberFormat.currency(symbol: '$currencySymbol ', decimalDigits: 2).format(value)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        maxLines: 1,
      ),
    );
  }
  
  int _getActualIndex(DateTime date, bool isExpense, int combinedIndex) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _allExpenses[key]?.length ?? 0;
    final dailyIncomes = _allIncomes[key]?.length ?? 0;
    
    if (isExpense) {
      // If it's an expense, we just need to make sure the index is within expenses
      if (combinedIndex < dailyExpenses) {
        return combinedIndex;
      }
    } else {
      // If it's an income, we need to adjust the index by subtracting the number of expenses
      if (combinedIndex >= dailyExpenses && combinedIndex < (dailyExpenses + dailyIncomes)) {
        return combinedIndex - dailyExpenses;
      }
    }
    return -1; // Invalid index
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction, int index, bool isExpense) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = currencyProvider.currencySymbol;
    final loc = AppLocalizations.of(context);

    final Color color = isExpense ? Colors.red.shade400 : Colors.green.shade400;
    final IconData icon = isExpense ? Icons.remove : Icons.add;
    final String sign = isExpense ? '-' : '+';

    // Convert time string to TimeOfDay
    final timeParts = (transaction['time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Dismissible(
        key: Key('transaction-$index-${transaction['name']}-${transaction['time']}'),
        background: Container(
          color: Theme.of(context).colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(loc.t('confirmDelete')),
              content: Text(loc.t('confirmDeletePrompt')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.t('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    loc.t('delete'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          final actualIndex = _getActualIndex(_selectedDay!, isExpense, index);
          if (actualIndex >= 0) {
            _deleteTransaction(isExpense, _selectedDay!, actualIndex);
          }
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(transaction['name'] as String),
          subtitle: Text(
            loc.t('budgetCategoryLabel', args: {'category': transaction['category']}),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$sign${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2).format(transaction['amount'])}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
            ],
          ),
          onTap: () async {
            await showExpenseInputModal(
              context,
              _selectedDay!,
              (isExpenseArg, savedDate, newName, newAmount, newCategory, newTime) {
                final actualIndex = _getActualIndex(savedDate, isExpense, index);
                if (actualIndex >= 0) {
                  if (newName.isEmpty) {
                    // Empty name signals deletion
                    _deleteTransaction(isExpense, savedDate, actualIndex);
                  } else {
                    _updateTransaction(isExpense, savedDate, actualIndex, newName, newAmount, newCategory, newTime);
                  }
                }
              },
              initialExpense: {
                'name': transaction['name'],
                'amount': transaction['amount'],
                'category': transaction['category'],
                'time': time,
                'isExpense': isExpense,
              },
            );
          },
        ),
      ),
    );
  }



  Widget _buildTableCalendar() {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return TableCalendar(
      locale: loc.locale.languageCode,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = isSameDay(_selectedDay, selectedDay) ? null : selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() => _calendarFormat = format);
        }
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        _loadCategories();
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final dailyBalance = _calculateDailyBalanceForMarker(day);
          if (dailyBalance != 0) {
            final isPositive = dailyBalance > 0;
            final color = isPositive ? Colors.green.shade400 : Colors.red.shade400;
            final sign = isPositive ? '+' : '';
            
            return Positioned(
              right: 1, bottom: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  '$sign${NumberFormat.compact().format(dailyBalance)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }


}