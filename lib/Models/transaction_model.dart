import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String category; // 'Income' or 'Expense'

  TransactionModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}
