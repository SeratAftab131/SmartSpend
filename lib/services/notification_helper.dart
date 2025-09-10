import 'package:hive/hive.dart';
import '../models/settings_model.dart';
import 'data_repository.dart';
import 'notification_service.dart';

class NotificationHelper {
  static final DataRepository _dataRepository = DataRepository();

  static Future<void> dailySummary() async {
    final totalToday = await _dataRepository.getTodayTotal();
    final settingsBox = Hive.box<SettingsModel>('settings');

    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0)!;
      final percentage =
          (totalToday / settings.dailyBudgetLimit * 100).clamp(0, 100);

      await NotificationService.showNotification(
        title: "Daily Spending Summary",
        body:
            "You spent \$${totalToday.toStringAsFixed(2)} today (${percentage.toStringAsFixed(1)}% of budget).",
      );
    }
  }

  static Future<void> budgetAlert() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) return;

    final settings = settingsBox.getAt(0)!;
    final totalToday = await _dataRepository.getTodayTotal();

    if (totalToday >= settings.dailyBudgetLimit) {
      await NotificationService.showNotification(
        title: "Budget Alert",
        body:
            "You have reached your daily budget limit of \$${settings.dailyBudgetLimit.toStringAsFixed(2)}.",
      );
    }
  }

  static Future<void> categoryBudgetAlert() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) return;

    final settings = settingsBox.getAt(0)!;
    final categoryTotals = await _dataRepository.getCategoryTotals();

    for (var entry in categoryTotals.entries) {
      final category = entry.key;
      final total = entry.value;
      final limit = settings.getCategoryLimit(category);

      if (total >= limit) {
        await NotificationService.showNotification(
          title: "Category Budget Alert",
          body:
              "You have exceeded your $category budget of \$${limit.toStringAsFixed(2)}.",
        );
      }
    }
  }
}
