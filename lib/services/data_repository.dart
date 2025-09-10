import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class DataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box<ExpenseModel> _expensesBox = Hive.box<ExpenseModel>('expenses');

  bool _isMigrated = false;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<ExpenseModel>> getExpenses() {
    if (_userId != null) {
      if (!_isMigrated) {
        _syncCloudToLocalOnFirstLoad().then((_) {
          _isMigrated = true;
        });
      }

      return _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        await syncCloudToLocal();
        return snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
      });
    } else {
      return _expensesBox.watch().map((_) => _expensesBox.values.toList());
    }
  }

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

  Future<void> _syncCloudToLocalOnFirstLoad() async {
    if (_userId != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('expenses')
            .get();

        if (snapshot.docs.isNotEmpty && _expensesBox.isEmpty) {
          for (var doc in snapshot.docs) {
            final expense = ExpenseModel.fromFirestore(doc);
            await _expensesBox.add(expense);
          }
          print(
              'First-load sync: ${snapshot.docs.length} expenses from cloud to local');
        }
      } catch (e) {
        print('First-load sync error: $e');
      }
    }
  }

  Future<void> syncCloudToLocal() async {
    if (_userId != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('expenses')
            .get();

        await _expensesBox.clear();

        for (var doc in snapshot.docs) {
          final expense = ExpenseModel.fromFirestore(doc);
          await _expensesBox.add(expense);
        }

        print(
            'Manual sync: ${snapshot.docs.length} expenses from cloud to local');
      } catch (e) {
        print('Sync error: $e');
        throw e;
      }
    }
  }

  Future<Map<String, double>> getCategoryTotals() async {
    List<ExpenseModel> expenses;

    if (_userId != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('expenses')
          .get();

      expenses =
          snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    } else {
      expenses = _expensesBox.values.toList();
    }

    return _calculateCategoryTotals(expenses);
  }

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
}
