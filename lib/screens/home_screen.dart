import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'charts_screen.dart'; // import charts screen
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ExpenseModel>('expenses');

    return Scaffold(
      appBar: AppBar(
        title: Text('SmartSpend'),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartsScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ExpenseModel> box, _) {
          if (box.isEmpty) return Center(child: Text('No expenses added yet'));

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final expense = box.getAt(index)!;
              final color = categoryColors[expense.category] ?? Colors.grey;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color, // category color indicator
                  child: Text(
                    expense.category[0], // first letter of category
                    style: TextStyle(color: Colors.white),
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
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Expense'),
                            content: Text(
                              'Are you sure you want to delete "${expense.title}"?',
                            ),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text('Delete'),
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
        child: Icon(Icons.add),
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
