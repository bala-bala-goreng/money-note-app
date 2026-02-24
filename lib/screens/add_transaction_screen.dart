import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/money_note_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as m;
import '../utils/category_icons.dart';
import '../utils/decimal_input_formatter.dart';

/// Screen to add a new income or expense transaction.
/// User picks type (income/expense), category, enters description and amount.
class AddTransactionScreen extends StatefulWidget {
  /// Called after a transaction is saved successfully (e.g. switch to Home tab).
  final VoidCallback? onSaved;

  const AddTransactionScreen({super.key, this.onSaved});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = true;
  m.Category? _selectedCategory;
  DateTime _date = DateTime.now(); // Default to today if not picked
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  List<m.Category> _categories = [];
  static final _dateFormat = DateFormat('d MMM y');

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final provider = context.read<MoneyNoteProvider>();
    await provider.loadAll();
    if (mounted) {
      setState(() {
        _categories = provider.categories
            .where((c) => c.isIncome == _isIncome)
            .toList();
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onTypeChanged(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _categories = context.read<MoneyNoteProvider>().categories
          .where((c) => c.isIncome == isIncome)
          .toList();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    });
  }

  Future<void> _save() async {
    final desc = _descriptionController.text.trim();
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
    final t = TransactionRecord(
      description: desc,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      transactionDate: transactionDate,
      createdAt: DateTime.now(),
      isIncome: _isIncome,
    );

    await context.read<MoneyNoteProvider>().addTransaction(t);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction added'), backgroundColor: Colors.green),
    );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income / Expense toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: false, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (s) => _onTypeChanged(s.first),
            ),
            const SizedBox(height: 24),

            // Category dropdown
            DropdownButtonFormField<m.Category>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
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
            const SizedBox(height: 16),

            // Date (default today)
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 20),
              label: Text(_dateFormat.format(_date)),
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
            const SizedBox(height: 16),

            // Description (required)
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g. Lunch at cafe',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Amount (decimal, max 2 places)
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [DecimalInputFormatter(decimalPlaces: 2)],
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
