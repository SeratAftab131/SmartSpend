import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../models/settings_model.dart';
import '../services/data_repository.dart';
import '../services/notification_service.dart';
import 'add_expense_screen.dart';
import 'charts_screen.dart';
import 'login_screen.dart';
import 'setting_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataRepository _dataRepository = DataRepository();
  final Map<String, Color> categoryColors = {
    'Food': Colors.indigo,
    'Transport': Colors.teal,
    'Bills': Colors.orange,
    'Shopping': Colors.pink,
    'Health': Colors.green,
    'Other': Colors.blueGrey,
  };
  bool _isSyncing = false;
  bool _hasCloudData = false;

  @override
  void initState() {
    super.initState();
    _checkCloudData();
  }

  void _checkCloudData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('expenses')
            .get();

        setState(() {
          _hasCloudData = snapshot.docs.isNotEmpty;
        });

        if (_hasCloudData && Hive.box<ExpenseModel>('expenses').isEmpty) {
          _autoSyncOnLogin();
        }
      } catch (e) {
        print('Cloud data check error: $e');
      }
    }
  }

  void _autoSyncOnLogin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() => _isSyncing = true);
      try {
        await _dataRepository.syncCloudToLocal();
        // Removed the snackbar popup message
      } catch (e) {
        print('Auto-sync error: $e');
      } finally {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _manualSync() async {
    setState(() => _isSyncing = true);
    try {
      await _dataRepository.syncCloudToLocal();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _dataRepository.deleteExpense(expense);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSpend'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  )
                : Icon(_hasCloudData ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _isSyncing ? null : _manualSync,
            tooltip: _hasCloudData ? 'Cloud data available' : 'No cloud data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChartsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _dataRepository.getExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return _buildEmptyState();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkCategoryLimits(expenses);
          });

          return Column(
            children: [
              _buildBudgetSummary(expenses, userId != null),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final color =
                        categoryColors[expense.category] ?? Colors.grey;

                    return Dismissible(
                      key: Key(expense.id ?? expense.key.toString()),
                      background: Container(color: Colors.red),
                      onDismissed: (direction) => _deleteExpense(expense),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(
                            expense.category[0],
                            style: const TextStyle(color: Colors.white),
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(expense),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen()),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading expenses...'),
          if (_isSyncing) Text('Syncing with cloud...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Error loading expenses', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _manualSync,
            child: Text('Retry Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No expenses yet', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('Add your first expense to get started'),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(List<ExpenseModel> expenses, bool isLoggedIn) {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) return SizedBox();

    final settings = settingsBox.getAt(0)!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final todayTotal = expenses
        .where((expense) => expense.date.isAfter(todayStart))
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final budgetPercentage =
        (todayTotal / settings.dailyBudgetLimit * 100).clamp(0, 100);

    return Column(
      children: [
        if (isLoggedIn)
          Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(_hasCloudData ? Icons.cloud_done : Icons.cloud_off,
                  color: _hasCloudData ? Colors.green : Colors.orange),
              title: Text(
                  _hasCloudData ? 'Cloud Backup Active' : 'No Cloud Backup'),
              subtitle: Text(_hasCloudData
                  ? 'Your data is saved to your account'
                  : 'Add expenses to enable cloud backup'),
              trailing: _isSyncing
                  ? CircularProgressIndicator(strokeWidth: 2)
                  : IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _manualSync,
                    ),
            ),
          ),
        Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Spending',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '\$${todayTotal.toStringAsFixed(2)} / \$${settings.dailyBudgetLimit.toStringAsFixed(2)}'),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: budgetPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budgetPercentage > 90
                        ? Colors.red
                        : budgetPercentage > 75
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${budgetPercentage.toStringAsFixed(1)}% of daily budget',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _checkCategoryLimits(List<ExpenseModel> expenses) async {
    final settingsBox = Hive.box<SettingsModel>('settings');
    if (settingsBox.isEmpty) return;

    final settings = settingsBox.getAt(0)!;
    final Map<String, double> totals = {};

    for (var expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    totals.forEach((category, total) {
      final categoryLimit = settings.getCategoryLimit(category);
      if (total > categoryLimit) {
        NotificationService.showNotification(
          title: 'Budget Alert',
          body:
              'You have exceeded \$${categoryLimit.toStringAsFixed(2)} in $category.',
        );
      }
    });
  }
}
