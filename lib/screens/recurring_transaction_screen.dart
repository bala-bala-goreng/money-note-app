import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spendly_provider.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../utils/category_icons.dart';
import '../utils/currency_helper.dart';
import '../utils/decimal_input_formatter.dart';

/// Manage frequently transactions.
/// Split by income and expense. Uses favorite categories only.
class RecurringTransactionScreen extends StatefulWidget {
  const RecurringTransactionScreen({super.key});

  @override
  State<RecurringTransactionScreen> createState() =>
      _RecurringTransactionScreenState();
}

class _RecurringTransactionScreenState extends State<RecurringTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecurringTransaction> _recurringIncome = [];
  List<RecurringTransaction> _recurringExpense = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await context.read<SpendlyProvider>().loadAll();
    final provider = context.read<SpendlyProvider>();
    final income = await provider.getRecurringTransactions(isIncome: true);
    final expense = await provider.getRecurringTransactions(isIncome: false);
    if (mounted) {
      setState(() {
        _recurringIncome = income;
        _recurringExpense = expense;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Category> _categoriesForType(List<Category> all, bool isIncome) {
    return all.where((c) => c.isIncome == isIncome).toList();
  }

  void _showAddRecurring({required bool isIncome, RecurringTransaction? existing}) {
    final provider = context.read<SpendlyProvider>();
    bool formIsIncome = existing?.isIncome ?? isIncome;
    bool isReminderEnabled = existing?.isReminderEnabled ?? false;
    ReminderType reminderType = existing?.isReminderEnabled == true
        ? existing!.reminderType
        : ReminderType.endMonthMinus3;
    List<Category> categories = _categoriesForType(provider.categories, formIsIncome);
    if (categories.isEmpty && existing == null) return;

    final nameController = TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toString() : '',
    );
    Category? selectedCategory = existing != null
        ? _categoriesForType(provider.categories, existing.isIncome)
            .where((c) => c.id == existing.categoryId)
            .firstOrNull
        : (categories.isNotEmpty ? categories.first : null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          categories = _categoriesForType(provider.categories, formIsIncome);
          if (selectedCategory != null &&
              !categories.any((c) => c.id == selectedCategory!.id)) {
            selectedCategory = categories.isNotEmpty ? categories.first : null;
          } else if (selectedCategory == null && categories.isNotEmpty) {
            selectedCategory = categories.first;
          }

          return AlertDialog(
            title: Text(existing == null ? 'Add frequently transaction' : 'Edit frequently transaction'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Income / Expense toggle (like Add screen)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {formIsIncome},
                    onSelectionChanged: (s) {
                      setDialogState(() {
                        formIsIncome = s.first;
                        categories = _categoriesForType(
                          provider.categories,
                          formIsIncome,
                        );
                        selectedCategory =
                            categories.isNotEmpty ? categories.first : null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category dropdown
                  if (categories.isNotEmpty)
                    DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
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
                      onChanged: (c) =>
                          setDialogState(() => selectedCategory = c),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No categories yet. Add them in Category management.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Description (optional)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'e.g. Monthly rent, Netflix',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      DecimalInputFormatter(decimalPlaces: 2),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  // Monthly reminder
                  SwitchListTile(
                    title: const Text('Monthly reminder'),
                    subtitle: const Text('Remind to add this every month'),
                    value: isReminderEnabled,
                    onChanged: (v) =>
                        setDialogState(() => isReminderEnabled = v),
                  ),
                  if (isReminderEnabled) ...[
                    const SizedBox(height: 8),
                    SegmentedButton<ReminderType>(
                      segments: const [
                        ButtonSegment(
                          value: ReminderType.endMonthMinus3,
                          label: Text('End - 3d'),
                        ),
                        ButtonSegment(
                          value: ReminderType.startMonthPlus3,
                          label: Text('Start + 3d'),
                        ),
                      ],
                      selected: {reminderType},
                      onSelectionChanged: (s) =>
                          setDialogState(() => reminderType = s.first),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: categories.isEmpty
                    ? null
                    : () async {
                        final desc = nameController.text.trim();
                        final amountStr =
                            amountController.text.trim().replaceAll(',', '.');
                        if (selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a category'),
                            ),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountStr);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }
                final r = RecurringTransaction(
                  id: existing?.id,
                  categoryId: selectedCategory!.id!,
                  description: desc.trim(),
                  amount: amount,
                  isIncome: formIsIncome,
                  isReminderEnabled: isReminderEnabled,
                  reminderType: isReminderEnabled ? reminderType : ReminderType.none,
                );
                        if (existing == null) {
                          await provider.addRecurring(r);
                        } else {
                          await provider.updateRecurring(r);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          _load();
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SpendlyProvider>(
              builder: (context, provider, _) {
          final incomeCategories = _categoriesForType(provider.categories, true);
          final expenseCategories = _categoriesForType(provider.categories, false);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                isIncome: true,
                categories: incomeCategories,
                      items: _recurringIncome,
                      getCategoryById: provider.getCategoryById,
                      onAdd: () => _showAddRecurring(isIncome: true),
                      onEdit: (r) => _showAddRecurring(isIncome: true, existing: r),
                      onDelete: (r) => _confirmDelete(context, r),
                    ),
              _buildTabContent(
                isIncome: false,
                categories: expenseCategories,
                      items: _recurringExpense,
                      getCategoryById: provider.getCategoryById,
                      onAdd: () => _showAddRecurring(isIncome: false),
                      onEdit: (r) => _showAddRecurring(isIncome: false, existing: r),
                      onDelete: (r) => _confirmDelete(context, r),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RecurringTransaction r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete frequently transaction?'),
        content: Text('Remove "${r.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && r.id != null && context.mounted) {
      await context.read<SpendlyProvider>().deleteRecurring(r.id!);
      _load();
    }
  }

  Widget _buildTabContent({
    required bool isIncome,
    required List<Category> categories,
    required List<RecurringTransaction> items,
    required Category? Function(int id) getCategoryById,
    required VoidCallback onAdd,
    required void Function(RecurringTransaction) onEdit,
    required void Function(RecurringTransaction) onDelete,
  }) {
    return Column(
      children: [
        if (categories.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${isIncome ? 'income' : 'expense'} categories yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add categories in Category management first.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No frequently ${isIncome ? 'income' : 'expense'} transaction yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Add first'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final r = items[i];
                      final cat = getCategoryById(r.categoryId);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(getIconData(cat?.iconName ?? 'category')),
                          ),
                          title: Text(r.description),
                          subtitle: Text(cat?.name ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatAmountShort(r.amount),
                                style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => onEdit(r),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => onDelete(r),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: categories.isEmpty ? null : onAdd,
              icon: const Icon(Icons.add),
              label: Text(
                'Add frequently ${isIncome ? 'income' : 'expense'} transaction',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
