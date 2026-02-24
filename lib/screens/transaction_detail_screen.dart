import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as m;
import '../providers/money_note_provider.dart';
import '../utils/category_icons.dart';
import '../utils/decimal_input_formatter.dart';
import '../widgets/transaction_list_item.dart';

/// Detail list for expenses or income with filters: date range, category, description.
class TransactionDetailScreen extends StatefulWidget {
  final bool isIncome;

  const TransactionDetailScreen({super.key, required this.isIncome});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _categoryId; // null = all
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<TransactionRecord> _applyFilters(
    List<TransactionRecord> list,
    m.Category? Function(int) getCategoryById,
  ) {
    var result = list.where((t) => t.isIncome == widget.isIncome).toList();

    if (_fromDate != null) {
      final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      result = result.where((t) => t.transactionDate.isAfter(start) || t.transactionDate.isAtSameMomentAs(start)).toList();
    }
    if (_toDate != null) {
      final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
      result = result.where((t) => t.transactionDate.isBefore(end) || t.transactionDate.isAtSameMomentAs(end)).toList();
    }
    if (_categoryId != null) {
      result = result.where((t) => t.categoryId == _categoryId).toList();
    }
    final desc = _descriptionController.text.trim().toLowerCase();
    if (desc.isNotEmpty) {
      result = result.where((t) => t.description.toLowerCase().contains(desc)).toList();
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
    List<m.Category> categories,
    MoneyNoteProvider provider,
  ) {
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
    final title = widget.isIncome ? 'Income' : 'Expenses';
    final dateFormat = DateFormat('d MMM y');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<MoneyNoteProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories
              .where((c) => c.isIncome == widget.isIncome)
              .toList();
          final filtered = _applyFilters(provider.transactions, provider.getCategoryById);

          return Column(
            children: [
              // Filters
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_fromDate == null ? 'From' : dateFormat.format(_fromDate!)),
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (d != null) setState(() => _fromDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(_toDate == null ? 'To' : dateFormat.format(_toDate!)),
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? _fromDate ?? DateTime.now(),
                                  firstDate: _fromDate ?? DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (d != null) setState(() => _toDate = d);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...categories.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Search by description',
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No transactions match the filters.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            onTap: () => _showEditSheet(context, t, categories, provider),
                            child: TransactionListItem(transaction: t, category: cat),
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

/// Bottom sheet content for editing a transaction (description, amount, category).
/// Public so [BalanceDetailScreen] can reuse it.
class EditTransactionSheet extends StatefulWidget {
  final TransactionRecord transaction;
  final List<m.Category> categories;
  final MoneyNoteProvider provider;

  const EditTransactionSheet({
    required this.transaction,
    required this.categories,
    required this.provider,
  });

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late m.Category? _selectedCategory;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _selectedCategory = widget.provider.getCategoryById(widget.transaction.categoryId);
    if (_selectedCategory == null && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
    _date = DateTime(
      widget.transaction.transactionDate.year,
      widget.transaction.transactionDate.month,
      widget.transaction.transactionDate.day,
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit transaction', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 20),
              label: Text(DateFormat('d MMM y').format(_date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<m.Category>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(getIconData(c.iconName), size: 20),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final desc = _descController.text.trim();
    final amountStr = _amountController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return;
    }
    if (amountStr.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    final amount = double.tryParse(amountStr.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    final transactionDate = DateTime(_date.year, _date.month, _date.day);
    final updated = TransactionRecord(
      id: widget.transaction.id,
      description: desc,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      transactionDate: transactionDate,
      createdAt: widget.transaction.createdAt,
      isIncome: widget.transaction.isIncome,
    );
    await widget.provider.updateTransaction(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction updated'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }
}
