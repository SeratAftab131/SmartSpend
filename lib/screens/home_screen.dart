import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../services/data_repository.dart';
import '../services/notification_service.dart';
import 'add_expense_screen.dart';
import 'charts_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final DataRepository _dataRepository = DataRepository();
  final Map<String, Color> categoryColors = {
    'Food': Colors.indigo,
    'Transport': Colors.teal,
    'Bills': Colors.orange,
    'Shopping': Colors.pink,
    'Health': Colors.green,
    'Other': Colors.blueGrey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSpend'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _dataRepository.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses added yet'));
          }

          // Check for category limits
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkCategoryLimits(expenses);
          });

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final color = categoryColors[expense.category] ?? Colors.grey;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Text(
                    expense.category[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.category} - ${DateFormat('yyyy-MM-dd HH:mm').format(expense.date)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: Text(
                              'Are you sure you want to delete "${expense.title}"?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _dataRepository.deleteExpense(expense);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen()),
          );
        },
      ),
    );
  }

  void _checkCategoryLimits(List<ExpenseModel> expenses) async {
    const double categoryLimit = 100; // budget alert threshold
    final Map<String, double> totals = {};

    for (var expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    totals.forEach((category, total) {
      if (total > categoryLimit) {
        NotificationService.showNotification(
          title: 'Budget Alert',
          body:
              'You have exceeded \$${categoryLimit.toStringAsFixed(2)} in $category.',
        );
      }
    });
  }
}
