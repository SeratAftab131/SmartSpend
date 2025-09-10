import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/settings_model.dart';

class BudgetSettingsScreen extends StatefulWidget {
  @override
  _BudgetSettingsScreenState createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
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
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) {
      settings = SettingsModel();
      settingsBox.add(settings);
    } else {
      settings = settingsBox.getAt(0)!;
    }
  }

  void _saveSettings() {
    final settingsBox = Hive.box<SettingsModel>('settings');
    settingsBox.putAt(0, settings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Daily Budget Limit
            Card(
              child: ListTile(
                title: Text('Daily Budget Limit'),
                subtitle:
                    Text('\$${settings.dailyBudgetLimit.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showBudgetDialog(
                      'Daily Budget', settings.dailyBudgetLimit, (value) {
                    setState(() => settings.dailyBudgetLimit = value);
                  }),
                ),
              ),
            ),

            SizedBox(height: 20),

            Text('Category Limits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Category Limits
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final limit = settings.getCategoryLimit(category);

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(category[0]),
                      ),
                      title: Text(category),
                      subtitle: Text('Limit: \$${limit.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showBudgetDialog(
                            '$category Budget', limit, (value) {
                          setState(
                              () => settings.setCategoryLimit(category, value));
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(
      String title, double currentValue, Function(double) onSave) {
    final controller =
        TextEditingController(text: currentValue.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $title'),
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
              onSave(value);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
