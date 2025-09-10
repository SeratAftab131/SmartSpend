import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class DataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box<ExpenseModel> _expensesBox = Hive.box<ExpenseModel>('expenses');

  bool _isMigrated = false;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Get expenses stream
  Stream<List<ExpenseModel>> getExpenses() {
    if (_userId != null) {
      // Migrate data from Hive to Firestore on first login
      if (!_isMigrated) {
        _migrateHiveToFirestore();
        _isMigrated = true;
      }

      return _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList());
    } else {
      // Use local Hive data when not logged in
      return _expensesBox.watch().map((_) => _expensesBox.values.toList());
    }
  }

  // Add expense
  Future<void> addExpense(ExpenseModel expense) async {
    if (_userId != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .add(expense.toMap());
    } else {
      await _expensesBox.add(expense);
    }
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    if (_userId != null && expense.id != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
    } else if (expense.key != null) {
      await _expensesBox.put(expense.key, expense);
    }
  }

  // Delete expense
  Future<void> deleteExpense(ExpenseModel expense) async {
    if (_userId != null && expense.id != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .doc(expense.id)
          .delete();
    } else if (expense.key != null) {
      await _expensesBox.delete(expense.key);
    }
  }

  // Migrate Hive data to Firestore
  Future<void> _migrateHiveToFirestore() async {
    final hiveExpenses = _expensesBox.values.toList();
    if (hiveExpenses.isNotEmpty && _userId != null) {
      final batch = _firestore.batch();
      final expensesRef =
          _firestore.collection('users').doc(_userId).collection('expenses');

      for (var expense in hiveExpenses) {
        final docRef = expensesRef.doc();
        batch.set(docRef, expense.toMap());
      }

      await batch.commit();
      // Optionally clear Hive data after migration
      // await _expensesBox.clear();
    }
  }

  // Get category totals (for charts and notifications)
  Future<Map<String, double>> getCategoryTotals() async {
    if (_userId != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .get();

      final expenses =
          snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();

      return _calculateCategoryTotals(expenses);
    } else {
      return _calculateCategoryTotals(_expensesBox.values.toList());
    }
  }

  Map<String, double> _calculateCategoryTotals(List<ExpenseModel> expenses) {
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return categoryTotals;
  }

  // Get today's expenses total
  Future<double> getTodayTotal() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_userId != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date',
              isLessThan: Timestamp.fromDate(todayStart.add(Duration(days: 1))))
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    } else {
      return _expensesBox.values
          .where((expense) =>
              expense.date.isAfter(todayStart) &&
              expense.date.isBefore(todayStart.add(Duration(days: 1))))
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    }
  }
}
