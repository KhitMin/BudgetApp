import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/summary_card.dart';

class CategorySummary {
  final double totalAmount;
  final int transactionCount;

  CategorySummary({this.totalAmount = 0.0, this.transactionCount = 0});
}

class YearlyReportView extends StatelessWidget {
  final DateTime selectedDate;
  final double yearlyTotalIncome;
  final double yearlyTotalExpense;
  final Map<String, CategorySummary> yearlyCategorySummaries;
  final String currencySymbol;
  final double previousYearIncome;
  final double previousYearExpenses;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  
  const YearlyReportView({
    super.key,
    required this.selectedDate,
    required this.yearlyTotalIncome,
    required this.yearlyTotalExpense,
    required this.yearlyCategorySummaries,
    required this.currencySymbol,
    required this.previousYearIncome,
    required this.previousYearExpenses,
    required this.onPrevious,
    required this.onNext,
  });

  // Helper map to get icons for categories. You can expand this.
  static const Map<String, IconData> _categoryIcons = {
    'Food & Dining': Icons.fastfood_outlined,
    'Transportation': Icons.directions_car_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Entertainment': Icons.movie_outlined,
    'Bills & Utilities': Icons.receipt_long_outlined,
    'Health': Icons.local_hospital_outlined,
    'Home': Icons.home_outlined,
    'Other': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sortedYearlyExpenses = yearlyCategorySummaries.entries.toList()
      ..sort((a, b) => b.value.totalAmount.compareTo(a.value.totalAmount));

    return Column(
      children: [
        _buildDateNavigator(
          display: DateFormat.y(loc.locale.languageCode).format(selectedDate),
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildSummarySection(context),
              const SizedBox(height: 24),
              _buildExpensesByCategorySection(context, sortedYearlyExpenses),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Builds the summary section with Income, Expenses, and Remaining cards.
  Widget _buildSummarySection(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentRemaining = yearlyTotalIncome - yearlyTotalExpense;
    final previousRemaining = previousYearIncome - previousYearExpenses;

    return Column(
      children: [
        SummaryCard(
          icon: Icons.arrow_upward,
          iconBgColor: Colors.green.withOpacity(0.1),
          iconColor: Colors.green,
          title: loc.t('income'),
          currentAmount: yearlyTotalIncome,
          previousAmount: previousYearIncome,
          currencySymbol: currencySymbol,
          previousPeriodLabel: loc.t('lastYear'),
        ),
        const SizedBox(height: 12),
        SummaryCard(
          icon: Icons.arrow_downward,
          iconBgColor: Colors.red.withOpacity(0.1),
          iconColor: Colors.red,
          title: loc.t('expenses'),
          currentAmount: yearlyTotalExpense,
          previousAmount: previousYearExpenses,
          currencySymbol: currencySymbol,
          previousPeriodLabel: loc.t('lastYear'),
        ),
        const SizedBox(height: 12),
         SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          iconBgColor: Colors.blue.withOpacity(0.1),
          iconColor: Colors.blue,
          title: loc.t('remaining'),
          currentAmount: currentRemaining,
          previousAmount: previousRemaining,
          currencySymbol: currencySymbol,
          previousPeriodLabel: loc.t('lastYear'),
        ),
      ],
    );
  }
  
  Widget _buildExpensesByCategorySection(
    BuildContext context,
    List<MapEntry<String, CategorySummary>> sortedExpenses,
  ) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('reportYearlyExpensesByCategory'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (sortedExpenses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(loc.t('reportNoData')),
            ),
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedExpenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = sortedExpenses[index];
              final categoryName = entry.key;
              final summary = entry.value;
              final percentage = yearlyTotalExpense > 0
                  ? summary.totalAmount / yearlyTotalExpense
                  : 0.0;
              
              return _buildCategoryCard(
                context: context,
                icon: _categoryIcons[categoryName] ?? Icons.category_outlined,
                categoryName: categoryName,
                transactionCount: summary.transactionCount,
                amount: summary.totalAmount,
                percentage: percentage,
              );
            },
          ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String categoryName,
    required int transactionCount,
    required double amount,
    required double percentage,
  }) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName, style: theme.textTheme.titleMedium),
                    Text(
                      '$transactionCount transactions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      numberFormat.format(amount),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      percentFormat.format(percentage),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
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
}