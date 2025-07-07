import 'package:hive/hive.dart';
import 'transaction_model.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 1)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String category;

  @HiveField(1)
  final double limit;

  @HiveField(2)
  final String period; // 'monthly' or 'weekly'

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final String currency;

  BudgetModel({
    required this.category,
    required this.limit,
    required this.period,
    required this.startDate,
    required this.currency,
  });

  // Helper method to get current spending
  double getCurrentSpending(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfPeriod = _getStartOfPeriod(now);
    
    return transactions
        .where((tx) => 
            tx.category == category && 
            tx.date.isAfter(startOfPeriod) &&
            tx.date.isBefore(now.add(const Duration(days: 1)))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Helper method to get remaining budget
  double getRemainingBudget(List<TransactionModel> transactions) {
    return limit - getCurrentSpending(transactions);
  }

  // Helper method to get progress percentage
  double getProgressPercentage(List<TransactionModel> transactions) {
    final spending = getCurrentSpending(transactions);
    return spending / limit;
  }

  // Helper method to check if budget is exceeded
  bool isExceeded(List<TransactionModel> transactions) {
    return getCurrentSpending(transactions) > limit;
  }

  DateTime _getStartOfPeriod(DateTime date) {
    if (period == 'weekly') {
      return date.subtract(Duration(days: date.weekday - 1));
    } else {
      return DateTime(date.year, date.month, 1);
    }
  }
} 