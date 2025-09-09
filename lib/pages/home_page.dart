import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import 'widgets/settings_modal.dart';
import '../pages/widgets/notification_modal.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomePage({super.key, required this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  double _currentBalance = 0.0;
  double _monthlyBudget = 0.0;
  double _spentThisMonth = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _topCategories = {};
  List<Map<String, dynamic>> _upcomingBills = [];
  String _currencySymbol = '\$';

  // Helper map to get icons for categories
  final Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.fastfood_rounded,
    'Transportation': Icons.directions_car_rounded,
    'Entertainment': Icons.gamepad_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Coffee': Icons.coffee_rounded,
    'Gas': Icons.local_gas_station_rounded,
    'Subscription': Icons.subscriptions_rounded,
    'Pizza': Icons.local_pizza_rounded,
    'Default': Icons.wallet_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Listen for changes in SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.reload(); // Force reload preferences
      setState(() {
        _currencySymbol = prefs.getString('selectedCurrency') ?? 'MMK';
      });
    });
  }

  /// Loads all necessary data from SharedPreferences.
  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Load Balance, Budget and Currency
    _currentBalance = prefs.getDouble('current_balance') ?? 0.0;
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    _currencySymbol = prefs.getString('selectedCurrency') ?? 'MMK';
    // Debug print to check values
    print('Monthly Budget: $_monthlyBudget');
    print('Currency Symbol: $_currencySymbol');
    // Ensure preferences are up to date
    await prefs.reload();

    // Process Expenses
    final expensesString = prefs.getString('allExpenses');
    List<Map<String, dynamic>> allExpensesList = [];
    Map<String, double> categorySpending = {};
    double totalSpent = 0;

    if (expensesString != null) {
      final allExpenses = json.decode(expensesString) as Map<String, dynamic>;
      allExpenses.forEach((dateString, expenses) {
        final date = DateTime.parse(dateString);
        final expenseList = List<Map<String, dynamic>>.from(expenses);
        for (var expense in expenseList) {
          final expenseWithDate = {...expense, 'date': date.toIso8601String()};
          allExpensesList.add(expenseWithDate);

          if (date.year == now.year && date.month == now.month) {
            final amount = (expense['amount'] as num).toDouble();
            totalSpent += amount;
            final category = expense['category'] as String;
            categorySpending[category] =
                (categorySpending[category] ?? 0) + amount;
          }
        }
      });
    }
    _spentThisMonth = totalSpent;

    allExpensesList.sort(
      (a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
    );
    _recentTransactions = allExpensesList.take(5).toList();

    var sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topCategories = Map.fromEntries(sortedCategories.take(4));

    // Load Upcoming Bills
    final billsString = prefs.getString('upcoming_bills');
    if (billsString != null) {
      _upcomingBills = List<Map<String, dynamic>>.from(
        json.decode(billsString),
      );
      _upcomingBills.sort(
        (a, b) => DateTime.parse(
          a['dueDate'],
        ).compareTo(DateTime.parse(b['dueDate'])),
      );
    } else {
      _upcomingBills = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data for dynamic colors
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildBalanceCards(),
                    const SizedBox(height: 24),
                    _buildMonthlySummaryCard(),
                    const SizedBox(height: 24),
                    _buildRecentExpensesCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t('helloMessage'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat.yMMMM().format(DateTime.now()),
                style: TextStyle(color: theme.hintColor, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
            // 3. The call is now clean and simple.
            showModalBottomSheet(
              context: context,
              // Just build the modal directly.
              builder: (context) => const NotificationsModal(),
            );
          },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              // This single line will now open your settings modal
              showSettingsModal(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.account_balance_wallet_outlined,
            title: AppLocalizations.of(context).t('homeIncome'),
            amount: _currentBalance,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.arrow_downward_rounded,
            title: AppLocalizations.of(context).t('homeSpent'),
            amount: _spentThisMonth,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required double amount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title == AppLocalizations.of(context).t('homeIncome')
                                ? AppLocalizations.of(context).t('homeCurrent')
                                : AppLocalizations.of(context).t('homeThisMonth'),
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title == AppLocalizations.of(context).t('homeIncome')
                                ? AppLocalizations.of(context).t('homeBalance')
                                : AppLocalizations.of(context).t('homeSpent'),
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "${NumberFormat("#,##0").format(amount)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double progress = (_monthlyBudget > 0)
        ? (_spentThisMonth / _monthlyBudget).clamp(0, 1)
        : 0;
    final int remainingPercentage = ((1 - progress) * 100).toInt();

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).t('homeSummaryTitle', args: {
                    'month': DateFormat.MMMM().format(DateTime.now())
                  }),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              AppLocalizations.of(context).t('homeMonthlyOverview'),
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            if (_monthlyBudget > 0) ...[
              Row(
                children: [
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "${_currencySymbol}${NumberFormat("#,##0").format(_spentThisMonth)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${_currencySymbol}${NumberFormat("#,##0").format(_monthlyBudget)}',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppLocalizations.of(context).t('homeRemaining', args: {
                    'percent': remainingPercentage.toString()
                  }),
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocalizations.of(context).t('planningNoIncomePrompt')),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).t('homeTopCategories'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_topCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocalizations.of(context).t('reportNoData')),
                ),
              )
            else
              ..._topCategories.entries.map((entry) {
                return _buildCategoryItem(
                  icon: categoryIcons[entry.key] ?? categoryIcons['Default']!,
                  category: entry.key,
                  amount: entry.value,
                  percentage: _monthlyBudget > 0
                      ? (entry.value / _monthlyBudget * 100).toInt()
                      : 0,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String category,
    required double amount,
    required int percentage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        AppLocalizations.of(context).t('homePercentBudget', args: {'percent': percentage.toString()}),
        style: TextStyle(color: theme.hintColor),
      ),
      trailing: Text(
        "${_currencySymbol}${NumberFormat("#,##0").format(amount)}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildRecentExpensesCard() {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The TextButton and Row have been removed, leaving only the title.
            Text(
              AppLocalizations.of(context).t('homeRecentTransactions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Added a small gap for better spacing after removing the button row
            const SizedBox(height: 8.0),

            if (_recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(AppLocalizations.of(context).t('homeNoTransactions')),
                ),
              )
            else
              // The .take(3) here limits the list to only three items.
              ..._recentTransactions.take(3).map((tx) {
                final date = DateTime.parse(tx['date']);
                return _buildExpenseItem(
                  icon:
                      categoryIcons[tx['category']] ??
                      categoryIcons['Default']!,
                  name: tx['name'],
                  time: DateFormat.yMMMd().add_jm().format(date),
                  amount: (tx['amount'] as num).toDouble(),
                  category: tx['category'],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem({
    required IconData icon,
    required String name,
    required String time,
    required double amount,
    required String category,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
      title: Text(
        AppLocalizations.of(context).t(name), 
        style: const TextStyle(fontWeight: FontWeight.w500)
      ),
      subtitle: Text(time, style: TextStyle(color: theme.hintColor)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "-${_currencySymbol}${NumberFormat("#,##0").format(amount)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            category,
            style: TextStyle(color: theme.hintColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}