import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../models/settings_model.dart';
import '../services/data_repository.dart';
import '../services/notification_service.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final DataRepository _dataRepository = DataRepository();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Other'
  ];

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = ExpenseModel(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
      );

      await _dataRepository.addExpense(expense);

      // Check category budget limit
      final categoryTotals = await _dataRepository.getCategoryTotals();
      final categoryTotal = categoryTotals[_selectedCategory] ?? 0;

      // Retrieve budget limit from settings
      final settingsBox = Hive.box<SettingsModel>('settings');
      final limit = settingsBox.isNotEmpty
          ? settingsBox.getAt(0)?.budgetLimit ?? 100.0
          : 100.0;

      if (categoryTotal > limit) {
        await NotificationService.showNotification(
          title: 'Budget Alert',
          body:
              'You have spent \$${categoryTotal.toStringAsFixed(2)} on $_selectedCategory! (Limit: \$${limit.toStringAsFixed(2)})',
        );
      }

      Navigator.pop(context); // return to home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter a title' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              DropdownButtonFormField(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value as String),
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
