import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../providers/currency_provider.dart';
import '../../l10n/app_localizations.dart';

// A simple model for our categories
class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon.codePoint};
  factory Category.fromJson(Map<String, dynamic> json) => Category(
        name: json['name'],
        icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      );
}

/// Shows a modal for adding/editing an expense OR an income.
Future<void> showExpenseInputModal(
  BuildContext context,
  DateTime day,
  Function(bool isExpense, DateTime date, String name, double amount, String category, TimeOfDay time) onSave, {
  Map<String, dynamic>? initialExpense, // Note: Editing is only supported for expenses for now
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    builder: (context) {
      return ExpenseInputSheet(
        day: day,
        onSave: onSave,
        initialExpense: initialExpense,
      );
    },
  );
}

class ExpenseInputSheet extends StatefulWidget {
  final DateTime day;
  final Function(bool isExpense, DateTime date, String name, double amount, String category, TimeOfDay time) onSave;
  final Map<String, dynamic>? initialExpense;

  const ExpenseInputSheet({
    super.key,
    required this.day,
    required this.onSave,
    this.initialExpense,
  });

  @override
  State<ExpenseInputSheet> createState() => _ExpenseInputSheetState();
}

class _ExpenseInputSheetState extends State<ExpenseInputSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  // State variables
  late List<Category> _categories;
  Category? _selectedCategory;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoadingCategories = true;
  bool _isExpense = true; // true for Expense, false for Income

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (_isEditing) {
      _nameController.text = widget.initialExpense!['name'];
      _amountController.text = widget.initialExpense!['amount'].toString();
    }
  }
  
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    
    List<Category> loadedCategories;
    String prefsKey;

    if (_isExpense) {
      prefsKey = 'user_expense_categories';
      loadedCategories = [
        Category(name: 'Food', icon: Icons.fastfood_rounded),
        Category(name: 'Transport', icon: Icons.directions_car_rounded),
        Category(name: 'Shopping', icon: Icons.shopping_bag_rounded),
        Category(name: 'Fun', icon: Icons.gamepad_rounded),
        Category(name: 'Home', icon: Icons.home_rounded),
        Category(name: 'Health', icon: Icons.favorite_rounded),
        Category(name: 'Education', icon: Icons.school_rounded),
      ];
    } else { // Income categories
      prefsKey = 'user_income_categories';
      loadedCategories = [
        Category(name: 'Salary', icon: Icons.wallet_rounded),
        Category(name: 'Gift', icon: Icons.card_giftcard_rounded),
        Category(name: 'Bonus', icon: Icons.star_rounded),
        Category(name: 'Other Income', icon: Icons.attach_money_rounded),
      ];
    }

    final prefs = await SharedPreferences.getInstance();
    final customCategoriesString = prefs.getString(prefsKey);
    if (customCategoriesString != null) {
      final List<dynamic> customCategoriesJson = json.decode(customCategoriesString);
      loadedCategories.addAll(customCategoriesJson.map((jsonItem) => Category.fromJson(jsonItem)));
    }
    
    loadedCategories.add(Category(name: 'Other', icon: Icons.add_rounded));

    setState(() {
      _categories = loadedCategories;
      // Set initial category selection
      if (_isEditing && _isExpense) {
         _selectedCategory = _categories.firstWhere(
           (c) => c.name == widget.initialExpense!['category'], 
           orElse: () => _categories.first,
         );
      } else {
        _selectedCategory = _categories.first;
      }
      _isLoadingCategories = false;
    });
  }
  
  Future<void> _saveNewCategory(Category newCategory) async {
    final prefs = await SharedPreferences.getInstance();
    final prefsKey = _isExpense ? 'user_expense_categories' : 'user_income_categories';
    
    final customCategoriesString = prefs.getString(prefsKey);
    List<dynamic> customCategoriesJson = customCategoriesString != null ? json.decode(customCategoriesString) : [];
    
    customCategoriesJson.add(newCategory.toJson());
    await prefs.setString(prefsKey, json.encode(customCategoriesJson));

    await _loadCategories();
    setState(() {
       _selectedCategory = _categories.firstWhere((c) => c.name == newCategory.name);
    });
  }

  void _handleSave() {
    final loc = AppLocalizations.of(context);
    if (_nameController.text.isEmpty || _amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('fillAllFields'))),
      );
      return;
    }
    final name = _nameController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    widget.onSave(_isExpense, widget.day, name, amount, _selectedCategory!.name, _selectedTime);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _isEditing
                ? loc.t('modalEditExpense')
                : (_isExpense ? loc.t('modalAddExpense') : loc.t('modalAddIncome')),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!_isEditing) _buildTypeSwitcher(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: loc.t('modalExpenseName'),
              hint: _isExpense ? loc.t('lunchAtSubway') : loc.t('monthlySalary'),
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _amountController,
              label: loc.t('modalAmountLabel'),
              hint: '0.00',
              icon: Icons.monetization_on_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: '$currencySymbol ',
            ),
            const SizedBox(height: 24),
            Text(loc.t('modalCategory'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _isLoadingCategories 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildCategoryGrid(),
            const SizedBox(height: 24),
            Text(loc.t('modalTimeOptional'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildTimePicker(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isEditing ? loc.t('modalSaveChanges') : loc.t('modalSave'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher() {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Center(
      child: ToggleButtons(
        isSelected: [_isExpense, !_isExpense],
        onPressed: (index) {
          setState(() {
            _isExpense = index == 0;
            _loadCategories(); // Reload categories for the selected type
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        selectedColor: theme.colorScheme.onPrimary,
        color: theme.colorScheme.onSurfaceVariant,
        fillColor: theme.colorScheme.primary,
        constraints: BoxConstraints(
          minHeight: 40.0,
          minWidth: (MediaQuery.of(context).size.width - 60) / 2, // Adjust width
        ),
        children: [
          Text(loc.t('expense')),
          Text(loc.t('income')),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            prefixText: prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
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
              setState(() {
                _selectedCategory = category;
              });
            }
          },
          child: _CategoryChip(
            category: category,
            isSelected: isSelected,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildTimePicker() {
    final theme = Theme.of(context);
    final formattedTime = _selectedTime.format(context);

    return InkWell(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (pickedTime != null) {
          setState(() {
            _selectedTime = pickedTime;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedTime, style: theme.textTheme.bodyLarge),
            Icon(Icons.access_time_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showAddCategoryDialog() async {
    final newCategory = await showDialog<Category>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
    if (newCategory != null) {
      await _saveNewCategory(newCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}


// --- Helper Widgets for the Modal ---

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
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 20, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            category.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
    Icons.star_rounded, Icons.card_giftcard_rounded, Icons.local_cafe_rounded,
    Icons.pets_rounded, Icons.flight_rounded, Icons.movie_filter_rounded,
    Icons.sports_esports_rounded, Icons.music_note_rounded, Icons.brush_rounded,
    Icons.build_rounded, Icons.phone_android_rounded, Icons.devices_other_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Add New Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
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
                      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                    ),
                    child: Icon(icon, color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final newCategory = Category(name: _nameController.text, icon: _selectedIcon);
              Navigator.pop(context, newCategory);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}