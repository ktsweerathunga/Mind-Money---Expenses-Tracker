import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_mind_expense_tracker/Models/transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  void _captureAsImage() async {
    final image = await _screenshotController.capture(pixelRatio: 2.0);
    if (image != null) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/chart.png';
      await File(path).writeAsBytes(image);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved PNG to $path')));
    }
  }

  void _captureAsPDF() async {
    final image = await _screenshotController.capture(pixelRatio: 2.0);
    if (image != null) {
      final pdf = pw.Document();
      final img = pw.MemoryImage(image);
      pdf.addPage(pw.Page(
        build: (c) => pw.Center(child: pw.Image(img)),
      ));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chart.pdf');
      await file.writeAsBytes(await pdf.save());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved PDF to ${file.path}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Hive.box<TransactionModel>('transactions').values.toList();

    final Map<String, double> incomeMap = {};
    final Map<String, double> expenseMap = {};

    for (var tx in transactions) {
      final key = DateFormat.yMMM().format(tx.date);
      if (tx.category == 'Income') {
        incomeMap[key] = (incomeMap[key] ?? 0) + tx.amount;
      } else {
        expenseMap[key] = (expenseMap[key] ?? 0) + tx.amount;
      }
    }

    final allMonths = {...incomeMap.keys, ...expenseMap.keys}.toList()
      ..sort((a, b) => DateFormat.yMMM().parse(a).compareTo(DateFormat.yMMM().parse(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _captureAsImage,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _captureAsPDF,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: allMonths.isEmpty
            ? const Center(child: Text('No data to show'))
            : Screenshot(
                controller: _screenshotController,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= allMonths.length) return const SizedBox.shrink();
                            return Text(
                              allMonths[index].split(' ')[0],
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(allMonths.length, (i) {
                      final month = allMonths[i];
                      return BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: incomeMap[month] ?? 0,
                          color: Colors.green,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: expenseMap[month] ?? 0,
                          color: Colors.red,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]);
                    }),
                    gridData: FlGridData(show: true),
                    groupsSpace: 12,
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
      ),
    );
  }
}
