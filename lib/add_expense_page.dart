import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box('expenses');
      box.add({
        'amount': double.parse(_amountController.text),
        'date': DateTime.now().toString().split(' ')[0], // Today's date
        'category': _selectedCategory,
        'name': _nameController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense Added!')),
      );

      // Clear the form
      _amountController.clear();
      _nameController.clear();
      setState(() {
        _selectedCategory = 'Food';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount (₩)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Expense Name / Note'),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
