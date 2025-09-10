import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  late Box<SettingsModel> settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<SettingsModel>('settings');

    // Load existing budget if set
    if (settingsBox.isNotEmpty) {
      final settings = settingsBox.getAt(0);
      _controller.text = settings?.budgetLimit.toString() ?? "";
    }
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final limit = double.parse(_controller.text);

      if (settingsBox.isEmpty) {
        settingsBox.add(SettingsModel(limit));
      } else {
        final settings = settingsBox.getAt(0);
        if (settings != null) {
          settings.budgetLimit = limit;
          settings.save();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget limit saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Daily Budget Limit (\$)",
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? "Enter a budget limit"
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBudget,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
