import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'widgets/expense_input_modal.dart';
import '../providers/currency_provider.dart';

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
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // initState မှာ context မရသေးတဲ့အတွက် _loadData ကို တိုက်ရိုက်ခေါ်ပါတယ်
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    await _loadAllExpenses();
    await _loadCategories();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesString = prefs.getString('allExpenses');
    if (expensesString != null) {
      final decodedData = json.decode(expensesString) as Map<String, dynamic>;
      _allExpenses = decodedData.map(
        (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
      );
    }
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allExpenses', json.encode(_allExpenses));
  }

  void _addExpense(DateTime date, String name, double amount, String category) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);
    dailyExpenses.add({'name': name, 'amount': amount, 'category': category});
    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs();
    setState(() {});
  }

  void _updateExpense(
    DateTime date,
    int index,
    String name,
    double amount,
    String category,
  ) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);
    dailyExpenses[index] = {
      'name': name,
      'amount': amount,
      'category': category,
    };
    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs();
    setState(() {});
  }

  void _deleteExpense(DateTime date, int index) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);
    dailyExpenses.removeAt(index);
    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs();
    setState(() {});
  }

  Future<void> _loadCategories() async {
    final loc = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    final plansString = prefs.getString('all_plans');
    final currentMonthKey = DateFormat('yyyy-MM').format(_focusedDay);
    List<String> loadedCategories = [];

    if (plansString != null) {
      final allPlans = json.decode(plansString) as Map<String, dynamic>;
      if (allPlans.containsKey(currentMonthKey)) {
        final List<dynamic> currentMonthPlans = allPlans[currentMonthKey];
        loadedCategories = currentMonthPlans
            .map((plan) => plan['name'] as String)
            .toList();
      }
    }

    final uniqueCategories = loadedCategories.toSet().toList();

    if (mounted) {
      setState(() {
        if (uniqueCategories.isNotEmpty) {
          _categories = uniqueCategories;
          if (!_categories.contains(loc.t('others'))) {
            _categories.add(loc.t('others'));
          }
        } else {
          _categories = [loc.t('others')];
        }
      });
    }
  }

  List<Map<String, dynamic>> _getDailyExpenses(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    return _allExpenses[key] ?? [];
  }

  double _calculateMonthlyTotal(DateTime focusedDay) {
    double total = 0.0;
    _allExpenses.forEach((dateString, expenses) {
      try {
        final date = DateTime.parse(dateString);
        if (date.month == focusedDay.month && date.year == focusedDay.year) {
          for (var expense in expenses) {
            total += (expense['amount'] as num).toDouble();
          }
        }
      } catch (e) {
        print("Error parsing date: $dateString");
      }
    });
    return total;
  }

  double _calculateDailyTotal(DateTime day) {
    return _getDailyExpenses(
      day,
    ).fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currencySymbol = currencyProvider.currencySymbol;

    if (_selectedDay == null) {
      return Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Text(
                DateFormat.yMMMM(loc.locale.languageCode).format(_focusedDay),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildTableCalendar()),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                loc.t('budgetSelectDayPrompt'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } else {
      final dailyExpenses = _getDailyExpenses(_selectedDay!);
      final monthlyTotal = _calculateMonthlyTotal(_focusedDay);
      return Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Wrap the first Text widget with Expanded
                      child: Text(
                        loc.t(
                          'budgetTotalFor',
                          args: {
                            'month': DateFormat.yMMMM(
                              loc.locale.languageCode,
                            ).format(_focusedDay),
                          },
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow
                            .ellipsis, // Add this to handle long text
                      ),
                    ),
                    const SizedBox(
                      width: 8.0,
                    ), // Add a small space between the two texts
                    Text(
                      NumberFormat.currency(
                        symbol: '$currencySymbol ',
                        decimalDigits: 0,
                      ).format(monthlyTotal),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildTableCalendar(),
            const SizedBox(height: 8.0),
            Expanded(
              child: dailyExpenses.isEmpty
                  ? Center(child: Text(loc.t('budgetNoExpenseForToday')))
                  : ListView.builder(
                      itemCount: dailyExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = dailyExpenses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(expense['name'] as String),
                            subtitle: Text(
                              loc.t(
                                'budgetCategoryLabel',
                                args: {'category': expense['category']},
                              ),
                            ),
                            trailing: Text(
                              NumberFormat.currency(
                                symbol: '$currencySymbol ',
                                decimalDigits: 0,
                              ).format(expense['amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              _showEditDeleteDialog(
                                context,
                                _selectedDay!,
                                index,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_selectedDay != null) {
              await showExpenseInputModal(
                context,
                _selectedDay!,
                _categories,
                _addExpense,
              );
              _loadData();
            }
          },
          tooltip: loc.t('budgetAddExpenseTooltip'),
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  Widget _buildTableCalendar() {
    final loc = AppLocalizations.of(context);
    return TableCalendar(
      locale: loc.locale.languageCode,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          if (isSameDay(_selectedDay, selectedDay)) {
            _selectedDay = null;
          } else {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          }
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        _loadCategories();
      },
      calendarStyle: const CalendarStyle(outsideDaysVisible: false),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final dailyTotal = _calculateDailyTotal(day);
          if (dailyTotal > 0) {
            return Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  NumberFormat.compact().format(dailyTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
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

  void _showEditDeleteDialog(BuildContext context, DateTime date, int index) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.t('action')),
          content: Text(loc.t('confirmDeletePrompt')),
          actions: <Widget>[
            TextButton(
              child: Text(loc.t('delete')),
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext c) {
                    return AlertDialog(
                      title: Text(loc.t('confirmDelete')),
                      content: Text(loc.t('confirmDeletePrompt')),
                      actions: [
                        TextButton(
                          child: Text(loc.t('cancel')),
                          onPressed: () => Navigator.of(c).pop(),
                        ),
                        TextButton(
                          child: Text(
                            loc.t('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.of(c).pop();
                            _deleteExpense(date, index);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            TextButton(
              child: Text(loc.t('edit')),
              onPressed: () async {
                Navigator.of(context).pop();
                final expenseToEdit = _getDailyExpenses(date)[index];
                await showExpenseInputModal(context, date, _categories, (
                  savedDate,
                  newName,
                  newAmount,
                  newCategory,
                ) {
                  _updateExpense(date, index, newName, newAmount, newCategory);
                }, initialExpense: expenseToEdit);
              },
            ),
          ],
        );
      },
    );
  }
}
