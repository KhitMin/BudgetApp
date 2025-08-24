import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Edit လုပ်နိုင်ရန် initialExpense ဆိုတဲ့ optional parameter တစ်ခု ထပ်တိုးထားပါသည်
Future<void> showExpenseInputModal(
  BuildContext context,
  DateTime day,
  List<String> categories,
  Function(DateTime date, String name, double amount, String category) onSave, {
  Map<String, dynamic>? initialExpense,
}) async {
  final bool isEditing = initialExpense != null;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String? selectedCategory;

  // Edit mode ဖြစ်ပါက data များကို ကြိုဖြည့်ထားပါမည်
  if (isEditing) {
    nameController.text = initialExpense['name'];
    amountController.text = initialExpense['amount'].toString();
    selectedCategory = initialExpense['category'];
  } else {
    selectedCategory = categories.isNotEmpty ? categories.first : null;
  }

  // Dropdown အတွက် category list ကိုပြင်ဆင်ပါ
  final List<String> dropdownCategories = List.from(categories);
  if (isEditing && !dropdownCategories.contains(selectedCategory)) {
    dropdownCategories.add(selectedCategory!);
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    isEditing ? 'Edit Expense' : 'Add Expense for ${DateFormat.yMMMd().format(day)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (MMK)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: dropdownCategories.toSet().toList().map((String category) { // toSet().toList() for safety
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
                      if (nameController.text.isEmpty ||
                          amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields!')),
                        );
                        return;
                      }
                      final name = nameController.text;
                      final amount =
                          double.tryParse(amountController.text) ?? 0.0;
                      final category = selectedCategory ?? 'Others';

                      onSave(day, name, amount, category);
                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Save Expense'),
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