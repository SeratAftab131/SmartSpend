import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import 'notification_service.dart';

class NotificationHelper {
  static Future<void> dailySummary() async {
    final box = Hive.box<ExpenseModel>('expenses');
    final today = DateTime.now();
    double totalToday = 0;

    for (int i = 0; i < box.length; i++) {
      final expense = box.getAt(i);
      if (expense != null &&
          expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day) {
        totalToday += expense.amount;
      }
    }

    await NotificationService.showNotification(
      title: "Daily Spending Summary",
      body: "You spent \$${totalToday.toStringAsFixed(2)} today.",
    );
  }

  static Future<void> budgetAlert(double limit) async {
    final box = Hive.box<ExpenseModel>('expenses');
    final today = DateTime.now();
    double totalToday = 0;

    for (int i = 0; i < box.length; i++) {
      final expense = box.getAt(i);
      if (expense != null &&
          expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day) {
        totalToday += expense.amount;
      }
    }

    if (totalToday >= limit) {
      await NotificationService.showNotification(
        title: "Budget Alert",
        body:
            "You have reached your daily budget limit of \$${limit.toStringAsFixed(2)}.",
      );
    }
  }
}
