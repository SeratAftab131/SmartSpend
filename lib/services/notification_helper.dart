import 'package:hive/hive.dart';
import '../models/settings_model.dart';
import 'data_repository.dart';
import 'notification_service.dart';

class NotificationHelper {
  static final DataRepository _dataRepository = DataRepository();

  static Future<void> dailySummary() async {
    final totalToday = await _dataRepository.getTodayTotal();

    await NotificationService.showNotification(
      title: "Daily Spending Summary",
      body: "You spent \$${totalToday.toStringAsFixed(2)} today.",
    );
  }

  static Future<void> budgetAlert() async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) return; // no budget set yet

    final settings = settingsBox.getAt(0); // single entry
    final double limit = settings?.budgetLimit ?? 0;

    final totalToday = await _dataRepository.getTodayTotal();

    if (limit > 0 && totalToday >= limit) {
      await NotificationService.showNotification(
        title: "Budget Alert",
        body:
            "You have reached your daily budget limit of \$${limit.toStringAsFixed(2)}.",
      );
    }
  }
}
