import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as m;
import '../providers/spendly_provider.dart';
import 'add_transaction_screen.dart';
import '../utils/category_icons.dart';
import '../utils/decimal_input_formatter.dart';
import '../widgets/transaction_list_item.dart';

/// Mode: expense only, income only, atau balance (keduanya).
enum TransactionDetailMode {
  expense,
  income,
  balance,
}

/// Satu screen untuk semua: Expense box, Balance box, Income box, dan Calendar.
/// - Dari box: filter by mode (expense/income/balance), all dates, bisa ubah date + category + search
/// - Dari calendar: sama tapi initialDate = tanggal yang dipilih (filter hanya hari itu)
class TransactionDetailScreen extends StatefulWidget {
  final TransactionDetailMode mode;
  /// Dari calendar: filter hanya tanggal ini. Null = all dates.
  final DateTime? initialDate;

  const TransactionDetailScreen({
    super.key,
    required this.mode,
    this.initialDate,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late DateTime? _fromDate;
  late DateTime? _toDate;
  Set<int> _selectedCategoryIds = const {}; // empty = All
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _fromDate = DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day);
      _toDate = DateTime(widget.initialDate!.year, widget.initialDate!.month, widget.initialDate!.day);
    } else {
      _fromDate = null;
      _toDate = null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<TransactionRecord> _applyFilters(
    List<TransactionRecord> list,
  ) {
    var result = list;
    switch (widget.mode) {
      case TransactionDetailMode.expense:
        result = result.where((t) => !t.isIncome).toList();
        break;
      case TransactionDetailMode.income:
        result = result.where((t) => t.isIncome).toList();
        break;
      case TransactionDetailMode.balance:
        break; // both
    }

    if (_fromDate != null) {
      final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      result = result.where((t) => !t.transactionDate.isBefore(start)).toList();
    }
    if (_toDate != null) {
      final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
      result = result.where((t) => !t.transactionDate.isAfter(end)).toList();
    }
    if (_selectedCategoryIds.isNotEmpty) {
      result = result.where((t) => _selectedCategoryIds.contains(t.categoryId)).toList();
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

  List<m.Category> _categoriesForFilter(SpendlyProvider provider) {
    switch (widget.mode) {
      case TransactionDetailMode.expense:
        return provider.categories.where((c) => !c.isIncome).toList();
      case TransactionDetailMode.income:
        return provider.categories.where((c) => c.isIncome).toList();
      case TransactionDetailMode.balance:
        return provider.categories;
    }
  }

  void _showEditSheet(
    BuildContext context,
    TransactionRecord t,
    SpendlyProvider provider,
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

  String get _title {
    switch (widget.mode) {
      case TransactionDetailMode.expense:
        return 'Expenses';
      case TransactionDetailMode.income:
        return 'Income';
      case TransactionDetailMode.balance:
        return 'Balance';
    }
  }

  DateTime? get _defaultAddDate {
    if (_fromDate == null && _toDate == null) return null;
    if (_fromDate != null &&
        _toDate != null &&
        _fromDate!.year == _toDate!.year &&
        _fromDate!.month == _toDate!.month &&
        _fromDate!.day == _toDate!.day) {
      return _fromDate;
    }
    return _fromDate ?? _toDate;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y');
    final categoriesForFilter = _categoriesForFilter;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                initialDate: _defaultAddDate,
                onSaved: () => Navigator.pop(context),
              ),
            ),
          );
          if (!mounted) return;
          context.read<SpendlyProvider>().loadAll();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Consumer<SpendlyProvider>(
        builder: (context, provider, _) {
          final categories = categoriesForFilter(provider);
          final filtered = _applyFilters(provider.transactions);

          return Column(
            children: [
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
                      _CategoryMultiComboBox(
                        selectedIds: _selectedCategoryIds,
                        categories: categories.where((c) => c.id != null).toList(),
                        onChanged: (ids) => setState(() => _selectedCategoryIds = ids),
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
                            onTap: () => _showEditSheet(context, t, provider),
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

/// Combo box multi-select untuk filter kategori.
class _CategoryMultiComboBox extends StatefulWidget {
  final Set<int> selectedIds;
  final List<m.Category> categories;
  final ValueChanged<Set<int>> onChanged;

  const _CategoryMultiComboBox({
    required this.selectedIds,
    required this.categories,
    required this.onChanged,
  });

  @override
  State<_CategoryMultiComboBox> createState() => _CategoryMultiComboBoxState();
}

class _CategoryMultiComboBoxState extends State<_CategoryMultiComboBox> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.categories.where((c) => widget.selectedIds.contains(c.id)).toList();
    final isEmpty = widget.selectedIds.isEmpty;

    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category',
          hintText: 'Select categories...',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: Icon(Icons.arrow_drop_down, size: 24),
        ),
        child: isEmpty
            ? const Text('All', style: TextStyle(color: Colors.grey))
            : Wrap(
                spacing: 4,
                runSpacing: 4,
                children: selected
                    .map((c) => Chip(
                          label: Text(c.name, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            widget.onChanged({...widget.selectedIds}..remove(c.id));
                          },
                        ))
                    .toList(),
              ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    _searchController.clear();
    setState(() => _query = '');
    Set<int> pending = Set.from(widget.selectedIds);
    final categories = widget.categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _query.trim().isEmpty
                ? categories
                : categories.where((c) => c.name.toLowerCase().contains(_query.trim().toLowerCase())).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                decoration: const InputDecoration(
                                  hintText: 'Search category...',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.search, size: 20),
                                ),
                                onChanged: (v) => setModalState(() => _query = v),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                pending = {};
                                setModalState(() {});
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView(
                          controller: scrollController,
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              leading: Icon(
                                pending.isEmpty ? Icons.check_box : Icons.check_box_outline_blank,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                              title: const Text('All'),
                              onTap: () {
                                pending = {};
                                setModalState(() {});
                              },
                            ),
                            ...filtered.map((c) {
                              final id = c.id!;
                              final checked = pending.contains(id);
                              return CheckboxListTile(
                                value: checked,
                                title: Text(c.name),
                                onChanged: (_) {
                                  if (checked) {
                                    pending = {...pending}..remove(id);
                                  } else {
                                    pending = {...pending, id};
                                  }
                                  setModalState(() {});
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              widget.onChanged(pending);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _searchController.clear();
      setState(() => _query = '');
    });
  }
}

/// Bottom sheet untuk edit transaksi.
class EditTransactionSheet extends StatefulWidget {
  final TransactionRecord transaction;
  final List<m.Category> categories;
  final SpendlyProvider provider;

  const EditTransactionSheet({
    super.key,
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
