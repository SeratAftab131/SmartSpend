import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ExpenseModel>('expenses');

    return Scaffold(
      appBar: AppBar(title: Text('SmartSpend')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<ExpenseModel> box, _) {
          if (box.isEmpty) return Center(child: Text('No expenses added yet'));

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final expense = box.getAt(index)!;
              return ListTile(
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.category} - ${DateFormat('yyyy-MM-dd HH:mm').format(expense.date)}',
                ),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
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
