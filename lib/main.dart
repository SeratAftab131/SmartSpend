import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense_model.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter());
  await Hive.openBox<ExpenseModel>('expenses');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSpend',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
    );
  }
}
