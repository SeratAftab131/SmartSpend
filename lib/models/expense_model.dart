import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime date;

  // Add ID field for Firestore
  String? id;

  ExpenseModel({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.id,
  });

  // Get Hive key (for local operations)
  int? get key {
    return super.key as int?;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
    };
  }

  // Create from Firestore document
  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      title: data['title'],
      amount: data['amount'].toDouble(),
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(),
      id: doc.id,
    );
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
