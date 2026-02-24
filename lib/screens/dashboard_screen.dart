import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/money_note_provider.dart';
import 'add_transaction_screen.dart';
import 'category_management_screen.dart';
import '../widgets/summary_box.dart';
import '../widgets/transaction_list.dart';

/// Main dashboard screen.
/// - Top: 3 summary boxes (Expense | Balance | Income)
/// - Below: TabBar with 2 tabs (Expenses list, Income list)
/// - FAB (+) adds new transaction; app bar icon opens category management
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load data when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoneyNoteProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryManagementScreen(),
                ),
              );
            },
            tooltip: 'Manage categories',
          ),
        ],
      ),
      body: Consumer<MoneyNoteProvider>(
        builder: (context, provider, _) {
          // Filter transactions by type for each tab
          final expenses =
              provider.transactions.where((t) => !t.isIncome).toList();
          final incomes =
              provider.transactions.where((t) => t.isIncome).toList();

          return Column(
            children: [
              // 3 summary boxes
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SummaryBox(
                      title: 'Expenses',
                      amount: currencyFormat.format(provider.totalExpense),
                      amountColor: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    SummaryBox(
                      title: 'Balance',
                      amount: currencyFormat.format(provider.balance),
                      amountColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    SummaryBox(
                      title: 'Income',
                      amount: currencyFormat.format(provider.totalIncome),
                      amountColor: Colors.green,
                    ),
                  ],
                ),
              ),
              // Tab bar directly below the 3 boxes
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Expenses'),
                    Tab(text: 'Income'),
                  ],
                ),
              ),
              // Tabbed transaction list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TransactionList(
                      transactions: expenses,
                      getCategoryById: provider.getCategoryById,
                    ),
                    TransactionList(
                      transactions: incomes,
                      getCategoryById: provider.getCategoryById,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (context.mounted) {
            context.read<MoneyNoteProvider>().loadAll();
          }
        },
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
