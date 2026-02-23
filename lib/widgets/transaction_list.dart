import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'transaction_list_item.dart';

/// List of transactions (income or expense).
/// Used in both tabs on the dashboard.
class TransactionList extends StatelessWidget {
  final List<TransactionRecord> transactions;
  final Category? Function(int) getCategoryById;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.getCategoryById,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No transactions yet.\nTap + to add one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final cat = getCategoryById(t.categoryId);
        return TransactionListItem(
          transaction: t,
          category: cat,
        );
      },
    );
  }
}
