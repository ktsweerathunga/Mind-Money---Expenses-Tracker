import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:money_mind_expense_tracker/Screens/transaction_screen.dart';
import '../Models/transaction_model.dart';
import 'summary_screen.dart';
import '../utils/export_csv.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _categoryFilter = 'All';
  DateTime? _selectedDate;
  String _currency = 'USD';
  final _currencies = ['USD', 'EUR', 'GBP', 'INR'];

  List<TransactionModel> _filterTransactions(Box<TransactionModel> box) {
    final transactions = box.values.toList();
    return transactions.where((tx) {
      final matchCategory = _categoryFilter == 'All' || tx.category == _categoryFilter;
      final matchDate = _selectedDate == null ||
          (tx.date.year == _selectedDate!.year &&
              tx.date.month == _selectedDate!.month &&
              tx.date.day == _selectedDate!.day);
      return matchCategory && matchDate;
    }).toList();
  }

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2022),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final Box<TransactionModel> transactionBox = Hive.box<TransactionModel>('transactions');

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('MoneyMind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final path = await exportToCSV();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported to: $path')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<TransactionModel> box, _) {
          final filtered = _filterTransactions(box);

          return Column(
            children: [
              _buildSummary(box),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _categoryFilter,
                      items: ['All', 'Income', 'Expense']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _categoryFilter = val!),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.date_range),
                      label: Text(_selectedDate == null
                          ? 'Any Date'
                          : DateFormat.yMd().format(_selectedDate!)),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _selectedDate = null),
                      ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _currency,
                      items: _currencies
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) => setState(() => _currency = val!),
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('lib/assets/lotties/empty_wallet.json', height: 200, repeat: true),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first transaction'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return Dismissible(
                        key: Key(tx.key.toString()),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          tx.delete();
                          setState(() {});
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: tx.category == 'Income'
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              child: Icon(
                                tx.category == 'Income'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              tx.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              DateFormat.yMMMMd().format(tx.date),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Text(
                              '$_currency ${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: tx.category == 'Income' ? Colors.green : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary(Box<TransactionModel> box) {
    final txs = box.values.toList();
    double income = 0, expense = 0;
    for (var tx in txs) {
      if (tx.category == 'Income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    final balance = income - expense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
          Text(
            '$_currency ${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryTile('Income', income, Colors.greenAccent),
              _summaryTile('Expense', expense, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text(
          '$_currency ${amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }
}
