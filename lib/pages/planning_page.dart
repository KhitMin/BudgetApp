import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';

// Main Page Widget
class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  Map<String, List<Map<String, dynamic>>> _allPlannedIncomes = {};
  Map<String, List<Map<String, dynamic>>> _allPlannedExpenses = {};
  double _totalIncome = 0.0;
  double _totalPlannedExpenses = 0.0;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- DATA MANAGEMENT ---

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final incomesString = prefs.getString('planned_incomes');
    if (incomesString != null) {
      _allPlannedIncomes = Map<String, List<Map<String, dynamic>>>.from(
          (json.decode(incomesString) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
      ));
    }
    final expensesString = prefs.getString('planned_expenses');
    if (expensesString != null) {
      _allPlannedExpenses = Map<String, List<Map<String, dynamic>>>.from(
          (json.decode(expensesString) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value)),
      ));
    }
    _calculateTotalsForCurrentMonth();
    if (mounted) setState(() {});
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planned_incomes', json.encode(_allPlannedIncomes));
    await prefs.setString('planned_expenses', json.encode(_allPlannedExpenses));
    _calculateTotalsForCurrentMonth();
  }

  // --- CALCULATIONS & ACTIONS ---

  void _calculateTotalsForCurrentMonth() {
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final currentIncomes = _allPlannedIncomes[currentMonthKey] ?? [];
    _totalIncome =
        currentIncomes.fold(0.0, (sum, item) => sum + (item['amount'] as num));
    final currentExpenses = _allPlannedExpenses[currentMonthKey] ?? [];
    _totalPlannedExpenses =
        currentExpenses.fold(0.0, (sum, item) => sum + (item['amount'] as num));
    if (mounted) setState(() {});
  }

  void _onItemSave(bool isExpense, String name, double amount, Category category,
      DateTime date, bool isRecurring) {
    final newItem = {
      'isExpense': isExpense,
      'name': name,
      'amount': amount,
      'category': category.toJson(),
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
    };
    final monthKey = DateFormat('yyyy-MM').format(date);
    setState(() {
      if (isExpense) {
        _allPlannedExpenses.putIfAbsent(monthKey, () => []).add(newItem);
      } else {
        _allPlannedIncomes.putIfAbsent(monthKey, () => []).add(newItem);
      }
    });
    _saveAllData();
  }

  void _onItemUpdate(
      Map<String, dynamic> oldItem,
      bool wasExpense,
      bool isExpense,
      String name,
      double amount,
      Category category,
      DateTime date,
      bool isRecurring) {
    final updatedItem = {
      'isExpense': isExpense,
      'name': name,
      'amount': amount,
      'category': category.toJson(),
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
    };
    final oldMonthKey =
        DateFormat('yyyy-MM').format(DateTime.parse(oldItem['date']));
    final newMonthKey = DateFormat('yyyy-MM').format(date);
    setState(() {
      if (wasExpense) {
        _allPlannedExpenses[oldMonthKey]?.removeWhere((item) =>
            item['date'] == oldItem['date'] && item['name'] == oldItem['name']);
      } else {
        _allPlannedIncomes[oldMonthKey]?.removeWhere((item) =>
            item['date'] == oldItem['date'] && item['name'] == oldItem['name']);
      }
      if (isExpense) {
        _allPlannedExpenses.putIfAbsent(newMonthKey, () => []).add(updatedItem);
      } else {
        _allPlannedIncomes.putIfAbsent(newMonthKey, () => []).add(updatedItem);
      }
    });
    _saveAllData();
  }

  void _onItemDelete(Map<String, dynamic> item, bool isExpense) {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.parse(item['date']));
    setState(() {
      if (isExpense) {
        _allPlannedExpenses[monthKey]?.remove(item);
      } else {
        _allPlannedIncomes[monthKey]?.remove(item);
      }
    });
    _saveAllData();
  }

  void _showPlanningModal({Map<String, dynamic>? item}) {
    bool isEditing = item != null;
    bool wasExpense = isEditing ? item['isExpense'] : false;
    showPlanningInputModal(context,
        isEditing ? DateTime.parse(item['date']) : _currentMonth, // MODIFIED: Use _currentMonth for new items
        onSave: (isExpense, name, amount, category, date, isRecurring) {
      if (isEditing) {
        _onItemUpdate(
            item, wasExpense, isExpense, name, amount, category, date, isRecurring);
      } else {
        _onItemSave(isExpense, name, amount, category, date, isRecurring);
      }
    }, onDelete: () {
      if (isEditing) {
        _onItemDelete(item, wasExpense);
      }
    }, initialItem: item);
  }

  // --- PIE CHART LOGIC ---
  List<PieChartSectionData> _getPieChartSections(
      Map<String, double> categoryTotals, List<Color> colors) {
    if (categoryTotals.isEmpty) {
      return [
        PieChartSectionData(
            color: Colors.grey.shade300, value: 1, title: '', radius: 50)
      ];
    }
    final totalValue =
        categoryTotals.values.fold(0.0, (sum, item) => sum + item);
    final dataEntries = categoryTotals.entries.toList();
    return List.generate(dataEntries.length, (index) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = colors[index % colors.length];
      final entry = dataEntries[index];
      final percentage =
          totalValue > 0 ? (entry.value / totalValue) * 100 : 0;
      return PieChartSectionData(
          color: color,
          value: entry.value,
          title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currencySymbol =
        Provider.of<CurrencyProvider>(context).currencySymbol;
    final currentMonthKey = DateFormat('yyyy-MM').format(_currentMonth);
    final incomesForCurrentMonth = _allPlannedIncomes[currentMonthKey] ?? [];
    final expensesForCurrentMonth = _allPlannedExpenses[currentMonthKey] ?? [];
    final remainingBalance = _totalIncome - _totalPlannedExpenses;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month - 1);
                          _calculateTotalsForCurrentMonth();
                        })),
                Text(DateFormat.yMMMM(loc.locale.languageCode).format(_currentMonth),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month + 1);
                          _calculateTotalsForCurrentMonth();
                        }))
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow(loc.t('planningTotalIncome'),
                            _totalIncome, Colors.green, currencySymbol),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                            loc.t('planningPlannedBudget'),
                            _totalPlannedExpenses,
                            Colors.red,
                            currencySymbol),
                        const Divider(height: 24),
                        _buildSummaryRow(
                            remainingBalance >= 0
                                ? loc.t('planningRemainingBalance')
                                : loc.t('planningOverspending'),
                            remainingBalance,
                            remainingBalance >= 0 ? Colors.teal : Colors.orange,
                            currencySymbol,
                            isTotal: true)
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  if (expensesForCurrentMonth.isNotEmpty)
                    _buildPieChartCard(context, expensesForCurrentMonth),
                  ExpansionTile(
                    title: Text(loc.t('planningIncomes')),
                    initiallyExpanded: true,
                    children: [
                      if (incomesForCurrentMonth.isEmpty)
                        Center(
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(loc.t('planningAddIncomePrompt'))))
                      else
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: incomesForCurrentMonth.length,
                            itemBuilder: (context, index) {
                              final item = incomesForCurrentMonth[index];
                              return _buildItemTile(item, false, currencySymbol);
                            })
                    ],
                  ),
                  ExpansionTile(
                    title: Text(loc.t('planningPlannedExpenses')),
                    initiallyExpanded: true,
                    children: [
                      if (expensesForCurrentMonth.isEmpty)
                        Center(
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(loc.t('planningAddPlanPrompt'))))
                      else
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expensesForCurrentMonth.length,
                            itemBuilder: (context, index) {
                              final item = expensesForCurrentMonth[index];
                              return _buildItemTile(item, true, currencySymbol);
                            })
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(loc.t('planningStart')),
              onPressed: _showPlanningModal,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
      BuildContext context, List<Map<String, dynamic>> expenses) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      final categoryData = expense['category'];
      // Handle both old (String) and new (Map) data formats
      final categoryName = categoryData is Map
          ? (categoryData)['name']
          : categoryData.toString();
      final amount = expense['amount'] as double;
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + amount;
    }
    const List<Color> pieColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.brown
    ];
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2), width: 1)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('expensePlanning'),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                      height: 150,
                      child: PieChart(PieChartData(
                          pieTouchData: PieTouchData(touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          }),
                          sections:
                              _getPieChartSections(categoryTotals, pieColors),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40))),
                  const SizedBox(height: 24),
                  _buildLegend(categoryTotals, pieColors)
                ])));
  }

  Widget _buildLegend(Map<String, double> categoryTotals, List<Color> colors) {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: List.generate(sortedEntries.length, (index) {
          final entry = sortedEntries[index];
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 12,
                height: 12,
                color: colors[index % colors.length]),
            const SizedBox(width: 6),
            Text(entry.key)
          ]);
        }));
  }

  Widget _buildSummaryRow(String title, double amount, Color color,
      String currencySymbol, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(NumberFormat.currency(symbol: currencySymbol).format(amount),
            style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: color))
      ],
    );
  }

  Widget _buildItemTile(
      Map<String, dynamic> item, bool isExpense, String currencySymbol) {
    final theme = Theme.of(context);
    final categoryValue = item['category'];
    Category category;
    if (categoryValue is Map<String, dynamic>) {
      category = Category.fromJson(categoryValue);
    } else {
      category =
          Category(name: categoryValue.toString(), icon: Icons.category);
    }
    final amount = item['amount'] as double;
    final iconData = category.icon;
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
            leading: CircleAvatar(child: Icon(iconData, size: 22)),
            title: Text(item['name']),
            subtitle: Text(category.name),
            trailing: Text(
                NumberFormat.currency(symbol: currencySymbol).format(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isExpense ? Colors.redAccent : Colors.green)),
            onTap: () => _showPlanningModal(item: item)));
  }
}

// =========================================================================
// MODAL LOGIC AND WIDGETS
// =========================================================================

class Category {
  final String name;
  final IconData icon;
  Category({required this.name, required this.icon});
  Map<String, dynamic> toJson() => {'name': name, 'icon': icon.codePoint};
  factory Category.fromJson(Map<String, dynamic> json) => Category(
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'));
}

Future<void> showPlanningInputModal(
    BuildContext context,
    DateTime day, {
    required Function(bool isExpense, String name, double amount,
            Category category, DateTime date, bool isRecurring)
        onSave,
    required VoidCallback onDelete,
    Map<String, dynamic>? initialItem,
  }) async {
  await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      builder: (context) => PlanningInputSheet(
          day: day,
          onSave: onSave,
          onDelete: onDelete,
          initialItem: initialItem));
}

class PlanningInputSheet extends StatefulWidget {
  final Function(bool isExpense, String name, double amount, Category category,
      DateTime date, bool isRecurring) onSave;
  final DateTime day;
  final VoidCallback onDelete;
  final Map<String, dynamic>? initialItem;

  const PlanningInputSheet(
      {super.key,
      required this.day,
      required this.onSave,
      required this.onDelete,
      this.initialItem});

  @override
  State<PlanningInputSheet> createState() => _PlanningInputSheetState();
}

class _PlanningInputSheetState extends State<PlanningInputSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  late List<Category> _categories;
  Category? _selectedCategory;
  late DateTime _selectedDate;
  late int _selectedDayOfMonth; // ADDED: For recurring day picking
  bool _isRecurring = false;
  bool _isLoadingCategories = true;
  late bool _isExpense;
  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _isExpense = _isEditing ? widget.initialItem!['isExpense'] : true;
    _selectedDate =
        _isEditing ? DateTime.parse(widget.initialItem!['date']) : widget.day;
    _isRecurring = _isEditing ? widget.initialItem!['isRecurring'] : false;
    _selectedDayOfMonth = _selectedDate.day; // Initialize day from date

    if (_isEditing) {
      _nameController.text = widget.initialItem!['name'];
      _amountController.text = widget.initialItem!['amount'].toString();
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    List<Category> loadedCategories;
    String prefsKey =
        _isExpense ? 'user_expense_categories' : 'user_income_categories';
    if (_isExpense) {
      loadedCategories = [
        Category(name: 'Food', icon: Icons.fastfood_rounded),
        Category(name: 'Transport', icon: Icons.directions_car_rounded),
        Category(name: 'Shopping', icon: Icons.shopping_bag_rounded)
      ];
    } else {
      loadedCategories = [
        Category(name: 'Salary', icon: Icons.wallet_rounded),
        Category(name: 'Gift', icon: Icons.card_giftcard_rounded),
        Category(name: 'Bonus', icon: Icons.star_rounded)
      ];
    }
    final prefs = await SharedPreferences.getInstance();
    final customCategoriesString = prefs.getString(prefsKey);
    if (customCategoriesString != null) {
      final List<dynamic> customCategoriesJson =
          json.decode(customCategoriesString);
      loadedCategories.addAll(
          customCategoriesJson.map((jsonItem) => Category.fromJson(jsonItem)));
    }
    loadedCategories.add(Category(name: 'Other', icon: Icons.add_rounded));
    setState(() {
      _categories = loadedCategories;
      if (_isEditing) {
        final categoryValue = widget.initialItem!['category'];
        Category savedCategory;
        if (categoryValue is Map<String, dynamic>) {
          savedCategory = Category.fromJson(categoryValue);
        } else {
          savedCategory = Category(name: categoryValue.toString(), icon: Icons.category);
        }
        _selectedCategory = _categories.firstWhere(
            (c) => c.name == savedCategory.name,
            orElse: () => _categories.first);
      } else {
        _selectedCategory = _categories.first;
      }
      _isLoadingCategories = false;
    });
  }

  Future<void> _saveNewCategory(Category newCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsKey =
        _isExpense ? 'user_expense_categories' : 'user_income_categories';
    final customCategoriesString = prefs.getString(prefsKey);
    List<dynamic> customCategoriesJson =
        customCategoriesString != null ? json.decode(customCategoriesString) : [];
    customCategoriesJson.add(newCategory.toJson());
    await prefs.setString(prefsKey, json.encode(customCategoriesJson));
    await _loadCategories();
    setState(() {
      _selectedCategory = _categories.firstWhere(
          (c) => c.name == newCategory.name,
          orElse: () => _categories.first);
    });
  }

  void _handleSave() {
    final loc = AppLocalizations.of(context);
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.t('fillAllFields'))));
      return;
    }
    final name = _nameController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // MODIFIED: Determine the correct date to save based on recurring status
    final DateTime dateToSave;
    if (_isRecurring) {
      // For recurring items, construct a date using the currently viewed month/year
      // and the selected day of the month.
      dateToSave = DateTime(widget.day.year, widget.day.month, _selectedDayOfMonth);
    } else {
      dateToSave = _selectedDate;
    }

    widget.onSave(
        _isExpense, name, amount, _selectedCategory!, dateToSave, _isRecurring);
    Navigator.pop(context);
  }

  void _handleDelete() {
    widget.onDelete();
    Navigator.pop(context);
  }

  Future<void> _showAddCategoryDialog() async {
    final newCategory = await showDialog<Category>(
        context: context, builder: (context) => const AddCategoryDialog());
    if (newCategory != null) {
      await _saveNewCategory(newCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final currencySymbol =
        Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
    return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
              Text(
                  _isEditing
                      ? loc.t('modalEditTransaction')
                      : loc.t('modalAddTransaction'),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (!_isEditing) _buildTypeSwitcher(),
              const SizedBox(height: 24),
              _buildTextField(
                  controller: _nameController,
                  label: loc.t('modalExpenseName'),
                  hint: _isExpense
                      ? loc.t('lunchAtSubway')
                      : loc.t('monthlySalary'),
                  icon: Icons.edit_note_rounded),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _amountController,
                  label: loc.t('modalAmountLabel'),
                  hint: '0.00',
                  icon: Icons.monetization_on_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '$currencySymbol '),
              const SizedBox(height: 24),
              Text(loc.t('modalCategory'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCategoryGrid(),
              const SizedBox(height: 24),

              // --- MODIFIED SECTION: Recurring checkbox is now before date picker ---
              _buildRecurringCheckbox(),
              const SizedBox(height: 16),
              Text(loc.t('planningDateLabel'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildDateOrDayPicker(), // This widget now handles both cases
              const SizedBox(height: 32),
              // --- END OF MODIFIED SECTION ---

              Row(children: [
                if (_isEditing)
                  IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: colorScheme.error),
                      onPressed: _handleDelete),
                Expanded(
                    child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(
                            _isEditing
                                ? loc.t('modalSaveChanges')
                                : loc.t('modalSave'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))))
              ]),
              const SizedBox(height: 20)
            ])));
  }

  Widget _buildTypeSwitcher() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Center(
        child: ToggleButtons(
            isSelected: [_isExpense, !_isExpense],
            onPressed: (index) => setState(() {
                  _isExpense = index == 0;
                  _loadCategories();
                }),
            borderRadius: BorderRadius.circular(12.0),
            selectedColor: theme.colorScheme.onPrimary,
            color: theme.colorScheme.onSurfaceVariant,
            fillColor: theme.colorScheme.primary,
            constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth: (MediaQuery.of(context).size.width - 60) / 2),
            children: [Text(loc.t('expense')), Text(loc.t('income'))]));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      String? prefixText,
      TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
              hintText: hint,
              prefixIcon:
                  Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              prefixText: prefixText,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.5)))))
    ]);
  }

  Widget _buildCategoryGrid() {
    return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _categories.map((category) {
          final isSelected = _selectedCategory?.name == category.name;
          return GestureDetector(
              onTap: () {
                if (category.name == 'Other') {
                  _showAddCategoryDialog();
                } else {
                  setState(() => _selectedCategory = category);
                }
              },
              child:
                  _CategoryChip(category: category, isSelected: isSelected));
        }).toList());
  }

Widget _buildDayGridForDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use a StatefulBuilder so the dialog can update its own UI on tap
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            final day = index + 1;
            // The selected day is now managed by the dialog's temporary state
            final isSelected = day == _selectedDayOfMonth;
            
            BoxDecoration decoration;
            Color textColor;

            if (isSelected) {
              decoration = BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              );
              textColor = colorScheme.onPrimaryContainer;
            } else {
              decoration = const BoxDecoration();
              textColor = colorScheme.onSurface;
            }

            return GestureDetector(
              onTap: () {
                // When a day is tapped, pop the dialog and return the day
                Navigator.of(context).pop(day);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: decoration,
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  // --- NEW: Function to show the overlayed day picker dialog ---
  Future<void> _showDayPickerOverlay() async {
    final selectedDay = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Day of Month"),
          contentPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
          content: SizedBox(
            width: 300, // Constrain the width of the dialog
            child: _buildDayGridForDialog(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            )
          ],
        );
      },
    );

    if (selectedDay != null) {
      setState(() {
        _selectedDayOfMonth = selectedDay;
      });
    }
  }

// MODIFIED: This widget now conditionally shows a day picker or a date picker
  Widget _buildDateOrDayPicker() {
    final theme = Theme.of(context);

    if (_isRecurring) {
      // Show a field that, when tapped, opens the day picker dialog
      return InkWell(
          onTap: _showDayPickerOverlay,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Day $_selectedDayOfMonth of the month", style: theme.textTheme.bodyLarge),
                    Icon(Icons.calendar_month_outlined,
                        color: theme.colorScheme.onSurfaceVariant)
                  ])));
    } else {
      // Otherwise, show the original full date picker
      final loc = AppLocalizations.of(context);
      final formattedDate =
          DateFormat.yMMMd(loc.locale.languageCode).format(_selectedDate);
      return InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030));
            if (pickedDate != null) {
              setState(() => _selectedDate = pickedDate);
            }
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formattedDate, style: theme.textTheme.bodyLarge),
                    Icon(Icons.calendar_month_rounded,
                        color: theme.colorScheme.onSurfaceVariant)
                  ])));
    }
  }

  Widget _buildRecurringCheckbox() {
    final loc = AppLocalizations.of(context);
    return CheckboxListTile(
        title: Text(loc.t('planningIsMonthlyRecurringLabel')),
        value: _isRecurring,
        onChanged: (value) => setState(() => _isRecurring = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero);
  }
}

// --- HELPER WIDGETS FOR THE MODAL ---
class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  const _CategoryChip({required this.category, required this.isSelected});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(category.icon,
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(category.name,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant))
        ]));
  }
}

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});
  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.star_rounded;
  final List<IconData> _availableIcons = [
    Icons.star_rounded,
    Icons.card_giftcard_rounded,
    Icons.local_cafe_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.movie_filter_rounded,
    Icons.sports_esports_rounded,
    Icons.music_note_rounded,
    Icons.brush_rounded,
    Icons.build_rounded,
    Icons.phone_android_rounded,
    Icons.devices_other_rounded
  ];
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
        title: const Text('Add New Category'),
        content: SingleChildScrollView(
            child:
                Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Category Name', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary, width: 2)
                                : null),
                        child: Icon(icon,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant)));
              }).toList())
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final newCategory = Category(
                      name: _nameController.text, icon: _selectedIcon);
                  Navigator.pop(context, newCategory);
                }
              },
              child: const Text('Save'))
        ]);
  }
}