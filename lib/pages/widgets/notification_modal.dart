import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    Map<String, dynamic> expensesData = {};
    if (expensesString != null && expensesString.isNotEmpty) {
      expensesData = json.decode(expensesString);
    }

    // --- The filtering logic below is the same as before ---
    final now = DateTime.now();
    final List<PlannedExpense> upcoming = [];

    expensesData.values.forEach((expenseList) {
      for (var expenseJson in expenseList) {
        final expense = PlannedExpense.fromJson(expenseJson as Map<String, dynamic>);

        if (expense.isRecurring) {
          int dayOfBill = expense.dueDate.day;
          DateTime upcomingDate = DateTime(now.year, now.month, dayOfBill);

          if (upcomingDate.isBefore(now)) {
            upcomingDate = DateTime(now.year, now.month + 1, dayOfBill);
          }
          
          upcoming.add(PlannedExpense(
            name: expense.name,
            amount: expense.amount,
            dueDate: upcomingDate,
            isRecurring: expense.isRecurring,
          ));
        } else {
          if (expense.dueDate.isAfter(now) &&
              expense.dueDate.month == now.month &&
              expense.dueDate.year == now.year) {
            upcoming.add(expense);
          }
        }
      }
    });

    upcoming.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // After processing, update the UI and set loading to false
    setState(() {
      _upcomingBills = upcoming;
      _isLoading = false;
    });
  }

  String _getDueDateSubtitle(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = dueDay.difference(today).inDays;

    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Due today';
    if (difference == 1) return 'Due tomorrow';
    
    return 'Due in $difference days (${dueDate.month}/${dueDate.day})';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Bills',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'You have no upcoming bills. ✨',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            // The list of bills
            ..._upcomingBills.map((bill) {
              return ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(bill.name),
                subtitle: Text(_getDueDateSubtitle(bill.dueDate)),
                trailing: Text(
                  '\$${bill.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}