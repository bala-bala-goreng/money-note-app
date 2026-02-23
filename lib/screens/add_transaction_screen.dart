import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_note_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as m;
import '../utils/category_icons.dart';

/// Screen to add a new income or expense transaction.
/// User picks type (income/expense), category, enters description and amount.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = true;
  m.Category? _selectedCategory;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  List<m.Category> _categories = [];

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
    if (desc.isEmpty || amountStr.isEmpty || _selectedCategory == null) {
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

    final t = TransactionRecord(
      description: desc,
      amount: amount,
      categoryId: _selectedCategory!.id!,
      createdAt: DateTime.now(),
      isIncome: _isIncome,
    );

    await context.read<MoneyNoteProvider>().addTransaction(t);
    if (mounted) {
      Navigator.pop(context);
    }
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
              value: _selectedCategory,
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

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Lunch at cafe',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
