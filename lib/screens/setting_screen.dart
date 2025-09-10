import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dailyBudgetController = TextEditingController();
  late Box<SettingsModel> settingsBox;
  late SettingsModel settings;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<SettingsModel>('settings');

    // Load existing settings or create new ones
    if (settingsBox.isEmpty) {
      settings = SettingsModel();
      settingsBox.add(settings);
    } else {
      settings = settingsBox.getAt(0)!;
    }

    _dailyBudgetController.text = settings.dailyBudgetLimit.toStringAsFixed(2);
  }

  void _saveSettings() {
    final dailyLimit = double.tryParse(_dailyBudgetController.text) ??
        settings.dailyBudgetLimit;
    settings.dailyBudgetLimit = dailyLimit;
    settings.save();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved")),
    );
  }

  void _showCategoryBudgetDialog(String category, double currentValue) {
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $category Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? currentValue;
              setState(() {
                settings.setCategoryLimit(category, value);
                settings.save();
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Budget Limit",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _dailyBudgetController,
                      decoration: const InputDecoration(
                        labelText: "Daily Budget Limit (\$)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Category Budget Limits",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    ..._categories.map((category) {
                      final limit = settings.getCategoryLimit(category);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(category[0]),
                        ),
                        title: Text(category),
                        subtitle: Text('Limit: \$${limit.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () =>
                              _showCategoryBudgetDialog(category, limit),
                        ),
                        onTap: () => _showCategoryBudgetDialog(category, limit),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Save All Settings"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
