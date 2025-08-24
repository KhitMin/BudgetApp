// lib/pages/budget_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'widgets/expense_input_modal.dart';

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
  List<String> _categories = ['Others'];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
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

  // =======================================================================
  // *** အသစ် ထပ်တိုးထားသော Helper Function ***
  // expense data တွေကို SharedPreferences မှာ သိမ်းဆည်းရန် function
  // =======================================================================
  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('allExpenses', json.encode(_allExpenses));
  }

  // Expense အသစ်တစ်ခု ထည့်ရန်
  void _addExpense(DateTime date, String name, double amount, String category) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);
    dailyExpenses.add({'name': name, 'amount': amount, 'category': category});
    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs(); // Data ကို သိမ်းဆည်း
    setState(() {});
  }

  // =======================================================================
  // *** အသစ် ထပ်တိုးထားသော Function ***
  // Expense တစ်ခုကို ပြင်ဆင်ရန်
  // =======================================================================
  void _updateExpense(
    DateTime date,
    int index,
    String name,
    double amount,
    String category,
  ) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);

    // index မှာရှိတဲ့ record ကို update လုပ်ပါ
    dailyExpenses[index] = {
      'name': name,
      'amount': amount,
      'category': category,
    };

    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs(); // Data ကို သိမ်းဆည်း
    setState(() {});
  }

  // =======================================================================
  // *** အသစ် ထပ်တိုးထားသော Function ***
  // Expense တစ်ခုကို ဖျက်ရန်
  // =======================================================================
  void _deleteExpense(DateTime date, int index) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final dailyExpenses = _getDailyExpenses(date);

    dailyExpenses.removeAt(index); // index မှာရှိတဲ့ record ကို ဖယ်ရှား

    _allExpenses[key] = dailyExpenses;
    _saveDataToPrefs(); // Data ကို သိမ်းဆည်း
    setState(() {});
  }

  Future<void> _loadCategories() async {
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

    // *** အဓိက ပြင်ဆင်မှု- Category နာမည်တူ (duplicate) များကို ဖယ်ရှားခြင်း ***
    // List ကို Set အဖြစ်ပြောင်းပြီး duplicate တွေဖယ်ရှားကာ List ပြန်ပြောင်းပါမည်။
    final uniqueCategories = loadedCategories.toSet().toList();

    setState(() {
      if (uniqueCategories.isNotEmpty) {
        _categories = uniqueCategories;
        if (!_categories.contains('Others')) {
          _categories.add('Others');
        }
      } else {
        _categories = ['Others'];
      }
    });
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
    if (_selectedDay == null) {
      return Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Text(
                DateFormat.yMMMM().format(_focusedDay),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildTableCalendar()),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'ကုန်ကျစရိတ်များ ကြည့်ရှုရန် သို့မဟုတ် ထည့်သွင်းရန် နေ့ရက်တစ်ခုကို ရွေးချယ်ပါ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
            // budget_page.dart ထဲတွင် အစားထိုးရန်
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  // *** ဤနေရာတွင် colorScheme ကို ပြောင်းသုံးပါ ***
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total for ${DateFormat.yMMMM().format(_focusedDay)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0').format(monthlyTotal)} MMK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // *** ဤနေရာတွင် colorScheme ကို ပြောင်းသုံးပါ ***
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
                  ? const Center(
                      child: Text('ယနေ့အတွက် ကုန်ကျစရိတ် မှတ်တမ်းမရှိပါ'),
                    )
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
                            subtitle: Text('Category: ${expense['category']}'),
                            trailing: Text(
                              '${NumberFormat('#,##0').format(expense['amount'])} MMK',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // =======================================================================
                            // *** အဓိက ပြောင်းလဲမှု ***
                            // ListTile ကို နှိပ်လိုက်ရင် edit/delete dialog ကို ခေါ်ပါမည်။
                            // =======================================================================
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
            // async ထည့်ပါ
            if (_selectedDay != null) {
              // အသစ်สร้างထားတဲ့ modal ကို ခေါ်သုံးပါ
              await showExpenseInputModal(
                context,
                _selectedDay!,
                _categories,
                _addExpense,
              );
              // modal ပိတ်ပြီးရင် data အသစ်ပြန် load လုပ်ပါ
              _loadData();
            }
          },
          tooltip: 'Add Expense',
          child: const Icon(Icons.add),
        ),
      );
    }
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
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

  // =======================================================================
  // *** အဓိက ပြောင်းလဲမှု ***
  // _showExpenseInputModal ကို edit လုပ်နိုင်ရန် ပြင်ဆင်ထားပါသည်။
  // index. આપવામાં આવેသောအခါ Edit mode, မဟုတ်ရင် Add mode ဖြစ်ပါသည်။
  // =======================================================================

  // =======================================================================
  // *** အသစ် ထပ်တိုးထားသော Function ***
  // Edit နှင့် Delete ခလုတ်များပါသော Dialog ကို ပြသရန်
  // =======================================================================
  void _showEditDeleteDialog(BuildContext context, DateTime date, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Action'),
          content: const Text('What would you like to do with this expense?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the action dialog
                // Show confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (BuildContext c) {
                    return AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text(
                        'Are you sure you want to delete this expense?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(c).pop(),
                        ),
                        TextButton(
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.of(c).pop(); // Close confirmation dialog
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
              child: const Text('Edit'),
              onPressed: () async {
                // async ထည့်ပါ
                Navigator.of(context).pop(); // Close the action dialog

                // ပြင်မယ့် expense data ကို ကြိုယူထားပါ
                final expenseToEdit = _getDailyExpenses(date)[index];

                // ပြင်ဆင်ထားတဲ့ modal အသစ်ကို ခေါ်သုံးပါ
                await showExpenseInputModal(
                  context,
                  date,
                  _categories,
                  (savedDate, newName, newAmount, newCategory) {
                    // modal ကနေ save နှိပ်လိုက်ရင် _updateExpense ကို ခေါ်ပါမယ်
                    _updateExpense(
                      date,
                      index,
                      newName,
                      newAmount,
                      newCategory,
                    );
                  },
                  initialExpense:
                      expenseToEdit, // ပြင်မယ့် data ကို ထည့်ပေးလိုက်ပါ
                );
              },
            ),
          ],
        );
      },
    );
  }
}
