import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/money_note_provider.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_detail_screen.dart';

/// Balance view: merged income and expense list, ordered by transaction date then created_at.
/// Filterable by category.
class BalanceDetailScreen extends StatefulWidget {
  const BalanceDetailScreen({super.key});

  @override
  State<BalanceDetailScreen> createState() => _BalanceDetailScreenState();
}

class _BalanceDetailScreenState extends State<BalanceDetailScreen> {
  int? _categoryId; // null = all

  List<TransactionRecord> _applyFilters(
    List<TransactionRecord> list,
  ) {
    var result = List<TransactionRecord>.from(list);
    if (_categoryId != null) {
      result = result.where((t) => t.categoryId == _categoryId).toList();
    }
    result.sort((a, b) {
      final dateCmp = b.transactionDate.compareTo(a.transactionDate);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  void _showEditSheet(
    BuildContext context,
    TransactionRecord t,
    MoneyNoteProvider provider,
  ) {
    final categories = provider.categories
        .where((c) => c.isIncome == t.isIncome)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionSheet(
        transaction: t,
        categories: categories,
        provider: provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balance')),
      body: Consumer<MoneyNoteProvider>(
        builder: (context, provider, _) {
          final allCategories = provider.categories;
          final filtered = _applyFilters(provider.transactions);

          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<int?>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...allCategories
                          .where((c) => c.id != null)
                          .map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No transactions.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final t = filtered[i];
                          final cat = provider.getCategoryById(t.categoryId);
                          return InkWell(
                            onTap: () =>
                                _showEditSheet(context, t, provider),
                            child: TransactionListItem(
                              transaction: t,
                              category: cat,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
