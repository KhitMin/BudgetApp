import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

// The PlannedExpense class remains the same
class PlannedExpense {
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;

  PlannedExpense({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
  });

  factory PlannedExpense.fromJson(Map<String, dynamic> json) {
    return PlannedExpense(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['date'] as String),
      isRecurring: json['isRecurring'] as bool,
    );
  }
}

class NotificationsModal extends StatefulWidget {
  // The constructor is now simple and takes no parameters
  const NotificationsModal({super.key});

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  List<PlannedExpense> _upcomingBills = [];
  // State variable to track the loading process
  bool _isLoading = true;
  String _selectedCurrency = 'MMK';  // Default currency

  @override
  void initState() {
    super.initState();
    // Fetch data when the widget is first created
    _fetchAndFilterBills();
  }

  /// Fetches data from SharedPreferences and then filters it.
  Future<void> _fetchAndFilterBills() async {
    // 1. Fetch from storage
    final prefs = await SharedPreferences.getInstance();
    final String? expensesString = prefs.getString('planned_expenses');
    final String currency = prefs.getString('selectedCurrency') ?? 'MMK';
    
    setState(() {
      _selectedCurrency = currency;
    });

    Map<String, dynamic> expensesData = {};
    if (expensesString != null && expensesString.isNotEmpty) {
      expensesData = json.decode(expensesString);
    }

    // --- The filtering logic below is the same as before ---
    final now = DateTime.now();
    final List<PlannedExpense> upcoming = [];

    for (var expenseList in expensesData.values) {
      for (var expenseJson in expenseList) {
        final expense = PlannedExpense.fromJson(expenseJson as Map<String, dynamic>);

        if (expense.isRecurring) {
          // Always set the date to current month for recurring expenses
          if (expense.dueDate.year == now.year && expense.dueDate.month == now.month) {

            // Only show if it's in the current month and not overdue
            if (!expense.dueDate.isBefore(now)) {
              upcoming.add(PlannedExpense(
                name: expense.name,
                amount: expense.amount,
                dueDate: expense.dueDate,
                isRecurring: expense.isRecurring,
              ));
            }
          }
        } else {
          // For non-recurring, only show if it's in the future
          if (!expense.dueDate.isBefore(now)) {
            upcoming.add(expense);
          }
        }
      }
    }

    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // After processing, update the UI and set loading to false
    setState(() {
      _upcomingBills = upcoming;
      _isLoading = false;
    });
  }

  String _getDueDateSubtitle(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = dueDay.difference(today).inDays;

    final localizations = AppLocalizations.of(context);

    if (difference < 0) return localizations.t('overdue');
    if (difference == 0) return localizations.t('dueToday');
    if (difference == 1) return localizations.t('dueTomorrow');
    
    return localizations.t('dueInDays', args: {
      'days': difference.toString(),
      'month': dueDate.month.toString(),
      'day': dueDate.day.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context);
              return Text(
                localizations.t('upcomingBills'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // 2. Conditionally show UI based on the loading state
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_upcomingBills.isEmpty)
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      localizations.t('noUpcomingBills'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                );
              },
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _upcomingBills.map((bill) {
                    return ListTile(
                      leading: const Icon(Icons.receipt_long_rounded),
                      title: Text(bill.name),
                      subtitle: Builder(
                        builder: (context) => Text(_getDueDateSubtitle(context, bill.dueDate)),
                      ),
                      trailing: Builder(
                        builder: (context) {
                          final localizations = AppLocalizations.of(context);
                          final key = 'currencyDisplayDefault';
                          return Text(
                            localizations.t(key, args: {
                              'amount': bill.amount.toStringAsFixed(0),
                              'currency': _selectedCurrency,
                            }),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}