import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _userName;

  final _currencies = ['USD', 'EUR', 'GBP', 'INR'];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? '';
    });
  }

  List<TransactionModel> _filterTransactions(Box<TransactionModel> box) =>
      box.values.where((tx) {
        final matchCategory = _categoryFilter == 'All' || tx.category == _categoryFilter;
        final matchDate = _selectedDate == null ||
            (tx.date.year == _selectedDate!.year &&
                tx.date.month == _selectedDate!.month &&
                tx.date.day == _selectedDate!.day);
        return matchCategory && matchDate;
      }).toList();

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
    final box = Hive.box<TransactionModel>('transactions');
    final filtered = _filterTransactions(box);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyMind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              final path = await exportToCSV();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported to: $path')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TransactionModel> b, _) {
          final filtered = _filterTransactions(b);

          return Column(
            children: [
              if (_userName != null && _userName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '👋 Hello, $_userName!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              _buildSummary(box, context),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
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
                    icon: const Icon(Icons.date_range_outlined),
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
                ]),
              ),
              filtered.isEmpty
                  ? Expanded(child: _buildEmptyState(context))
                  : Expanded(child: _buildTransactionList(filtered, context)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummary(Box<TransactionModel> box, BuildContext c) {
    final txs = box.values.toList();
    final income = txs.where((t) => t.category == 'Income').fold<double>(0, (a, t) => a + t.amount);
    final expense = txs.where((t) => t.category == 'Expense').fold<double>(0, (a, t) => a + t.amount);
    final balance = income - expense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(c).colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Theme.of(c).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total Balance', style: Theme.of(c).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          '$_currency ${balance.toStringAsFixed(2)}',
          style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _smallTile('Income', income, Colors.green),
          const SizedBox(width: 24),
          _smallTile('Expense', expense, Colors.red),
        ]),
      ]),
    );
  }

  Widget _smallTile(String label, double amount, Color accent) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: accent)),
          const SizedBox(height: 4),
          Text(
            '$_currency ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );

  Widget _buildEmptyState(BuildContext c) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Lottie.asset('lib/assets/lotties/empty_wallet.json', height: 180, repeat: true),
          const SizedBox(height: 16),
          Text('No transactions yet', style: Theme.of(c).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.add),
            label: const Text('Add your first transaction'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
          )
        ]),
      );

  Widget _buildTransactionList(List<TransactionModel> list, BuildContext c) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(indent: 72),
        itemBuilder: (_, i) {
          final tx = list[i];
          return Dismissible(
            key: Key(tx.key.toString()),
            direction: DismissDirection.startToEnd,
            background: Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.only(left: 20),
              alignment: Alignment.centerLeft,
              child: const Icon(Icons.delete_forever, size: 28, color: Colors.white),
            ),
            onDismissed: (_) {
              tx.delete();
              setState(() {});
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: tx.category == 'Income' ? Colors.teal : Colors.redAccent,
                  child: Icon(
                    tx.category == 'Income' ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(tx.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat.yMMMd().format(tx.date), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                trailing: Text(
                  '$_currency ${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tx.category == 'Income' ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
