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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen())),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(c).colorScheme.primary.withOpacity(0.1),
            Theme.of(c).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Theme.of(c).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(c).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(c).colorScheme.primary,
                        Theme.of(c).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(c).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_currency ${balance.toStringAsFixed(2)}',
                        style: Theme.of(c).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Theme.of(c).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _enhancedSmallTile('Income', income, Colors.green, c)),
                const SizedBox(width: 16),
                Expanded(child: _enhancedSmallTile('Expense', expense, Colors.red, c)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _enhancedSmallTile(String label, double amount, Color accent, BuildContext c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.8),
        border: Border.all(
          color: accent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: accent.withOpacity(0.1),
                ),
                child: Icon(
                  label == 'Income' ? Icons.trending_up : Icons.trending_down,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(c).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

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
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final tx = list[i];
          return _buildEnhancedTransactionCard(tx, c);
        },
      );

  Widget _buildEnhancedTransactionCard(TransactionModel tx, BuildContext c) {
    return Dismissible(
      key: Key(tx.key.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red, Colors.red.shade400],
          ),
        ),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete_forever, size: 28, color: Colors.white),
      ),
      onDismissed: (_) {
        tx.delete();
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: tx.category == 'Income'
                    ? [Colors.green, Colors.green.shade400]
                    : [Colors.red, Colors.red.shade400],
              ),
              boxShadow: [
                BoxShadow(
                  color: (tx.category == 'Income' ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              tx.category == 'Income' ? Icons.arrow_circle_down : Icons.arrow_circle_up,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            tx.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            DateFormat.yMMMd().format(tx.date),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(c).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (tx.category == 'Income' ? Colors.green : Colors.red).withOpacity(0.1),
              border: Border.all(
                color: (tx.category == 'Income' ? Colors.green : Colors.red).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$_currency ${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tx.category == 'Income' ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
