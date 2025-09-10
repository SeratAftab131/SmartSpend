import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  double dailyBudgetLimit;

  @HiveField(1)
  Map<String, double> categoryLimits;

  SettingsModel({
    this.dailyBudgetLimit = 100.0,
    Map<String, double>? categoryLimits,
  }) : categoryLimits = categoryLimits ??
            {
              'Food': 50.0,
              'Transport': 30.0,
              'Bills': 100.0,
              'Shopping': 40.0,
              'Health': 60.0,
              'Other': 20.0,
            };

  double getCategoryLimit(String category) {
    return categoryLimits[category] ?? 20.0;
  }

  void setCategoryLimit(String category, double limit) {
    categoryLimits[category] = limit;
  }
}
