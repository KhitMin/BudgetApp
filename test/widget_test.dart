// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

// Make sure to import your app's main entry point
import 'package:flutter_application_1/main.dart'; 

void main() {
  // A test to verify the budget app starts correctly
  testWidgets('Budget app smoke test', (WidgetTester tester) async {
    // 1. Build your app and trigger a frame to render the UI.
    await tester.pumpWidget(const MyApp());

    // 2. Verify that the app shows the current month's total header.
    // This checks if the main page has loaded.
    // We create the expected text exactly as it appears in your BudgetPage.
    final currentMonthText = 'Total for ${DateFormat.yMMMM().format(DateTime.now())}';
    expect(find.text(currentMonthText), findsOneWidget);

    // 3. Verify that the "Add Expense" button is visible on the screen.
    expect(find.text('Add Expense'), findsOneWidget);

    // 4. Verify that the prompt to select a day is shown initially.
    expect(find.text('Please select a day to view expenses.'), findsOneWidget);
  });
}