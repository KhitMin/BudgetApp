import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';
import '../../l10n/app_localizations.dart';

Future<void> showExpenseInputModal(
  BuildContext context,
  DateTime day,
  List<String> categories,
  Function(DateTime date, String name, double amount, String category) onSave, {
  Map<String, dynamic>? initialExpense,
}) async {
  final currencySymbol = Provider.of<CurrencyProvider>(context, listen: false).currencySymbol;
  final loc = AppLocalizations.of(context);
  final bool isEditing = initialExpense != null;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String? selectedCategory;

  if (isEditing) {
    nameController.text = initialExpense['name'];
    amountController.text = initialExpense['amount'].toString();
    selectedCategory = initialExpense['category'];
  } else {
    selectedCategory = categories.isNotEmpty ? categories.first : null;
  }

  final List<String> dropdownCategories = List.from(categories);
  if (isEditing && !dropdownCategories.contains(selectedCategory)) {
    if (selectedCategory != null) {
      dropdownCategories.add(selectedCategory);
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16.0, right: 16.0, top: 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    isEditing ? loc.t('modalEditExpense') : loc.t('modalAddExpenseFor', args: {'date': DateFormat.yMMMd(loc.locale.languageCode).format(day)}),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: loc.t('modalExpenseName'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: loc.t('modalAmount', args: {'currency': currencySymbol}),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: loc.t('modalCategory'),
                      border: const OutlineInputBorder(),
                    ),
                    items: dropdownCategories.toSet().toList().map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      modalSetState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isEmpty || amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.t('fillAllFields'))),
                        );
                        return;
                      }
                      final name = nameController.text;
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      final category = selectedCategory ?? loc.t('others');

                      onSave(day, name, amount, category);
                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? loc.t('modalSaveChanges') : loc.t('modalSaveExpense')),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
