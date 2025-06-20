import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import '../Models/transaction_model.dart';

Future<String> exportToCSV() async {
  final transactions = Hive.box<TransactionModel>('transactions').values.toList();

  List<List<String>> rows = [
    ['Title', 'Amount', 'Date', 'Category']
  ];

  for (var tx in transactions) {
    rows.add([
      tx.title,
      tx.amount.toString(),
      tx.date.toIso8601String(),
      tx.category,
    ]);
  }

  String csvData = const ListToCsvConverter().convert(rows);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/transactions.csv');
  await file.writeAsString(csvData);

  return file.path;
}
