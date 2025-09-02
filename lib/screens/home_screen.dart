import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartspend/services/notification_service.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'charts_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  // Define the same category colors as in ChartsScreen
  final Map<String, Color> categoryColors = {
    'Food': Colors.indigo,
    'Transport': Colors.teal,
    'Bills': Colors.orange,
    'Shopping': Colors.pink,
    'Health': Colors.green,
    'Other': Colors.blueGrey,
  };

  final double categoryLimit = 100; // budget alert threshold

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ExpenseModel>('expenses');

    void checkCategoryLimits() {
      final Map<String, double> totals = {};
      for (int i = 0; i < box.length; i++) {
        final expense = box.getAt(i);
        if (expense != null) {
          totals.update(
            expense.category,
            (value) => value + expense.amount,
            ifAbsent: () => expense.amount,
          );
        }
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
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ExpenseModel> box, _) {
          if (box.isEmpty)
            return const Center(child: Text('No expenses added yet'));

          // check for category limits whenever expenses change
          checkCategoryLimits();

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final expense = box.getAt(index)!;
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
                          box.deleteAt(index);
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
}
