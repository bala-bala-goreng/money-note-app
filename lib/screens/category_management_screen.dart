import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spendly_provider.dart';
import '../models/category.dart';
import '../utils/category_icons.dart';

/// Screen to view, add, and edit categories.
/// Shows list of categories with icons; tap to edit, FAB to add.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpendlyProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCategoryDialog({Category? existing, bool? defaultIsIncome}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final budgetController = TextEditingController(
      text: existing?.monthlyBudget?.toString() ?? '',
    );
    String iconName = existing?.iconName ?? 'category';
    bool isIncome = existing?.isIncome ?? defaultIsIncome ?? true;
    bool isFavorite = existing?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  controller: nameController,
                ),
                if (!isIncome) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly budget',
                      hintText: 'e.g. 1500000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Income')),
                    ButtonSegment(value: false, label: Text('Expense')),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (s) => setState(() {
                    isIncome = s.first;
                    if (isIncome) {
                      budgetController.clear();
                    }
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isFavorite,
                      onChanged: (v) => setState(() => isFavorite = v ?? false),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isFavorite = !isFavorite),
                      child: const Text('Favorite (show first in lists)'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: predefinedIconNames.map((iname) {
                    final selected = iconName == iname;
                    return InkWell(
                      onTap: () => setState(() => iconName = iname),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(getIconData(iname)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final budgetRaw = budgetController.text.trim();
                final parsedBudget = budgetRaw.isEmpty
                    ? null
                    : double.tryParse(budgetRaw.replaceAll(',', '.'));
                if (budgetRaw.isNotEmpty && parsedBudget == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid budget amount')),
                  );
                  return;
                }
                final cat = Category(
                  id: existing?.id,
                  name: name.trim(),
                  iconName: iconName,
                  isIncome: isIncome,
                  isFavorite: isFavorite,
                  monthlyBudget: (!isIncome && parsedBudget != null && parsedBudget > 0)
                      ? parsedBudget
                      : null,
                );
                final provider = context.read<SpendlyProvider>();
                if (existing == null) {
                  await provider.addCategory(cat);
                } else {
                  await provider.updateCategory(cat);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Category> _filteredCategories(List<Category> all, bool isIncome) {
    return all.where((c) => c.isIncome == isIncome).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: Consumer<SpendlyProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(
                _filteredCategories(categories, true),
                onAdd: () => _showCategoryDialog(defaultIsIncome: true),
              ),
              _buildCategoryList(
                _filteredCategories(categories, false),
                onAdd: () => _showCategoryDialog(defaultIsIncome: false),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(
          defaultIsIncome: _tabController.index == 0,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, {VoidCallback? onAdd}) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No ${_tabController.index == 0 ? 'income' : 'expense'} categories yet.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(getIconData(c.iconName)),
          ),
          title: Text(c.name),
          subtitle: (!c.isIncome && c.monthlyBudget != null && c.monthlyBudget! > 0)
              ? Text('Monthly budget: ${c.monthlyBudget!.toStringAsFixed(0)}')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  c.isFavorite ? Icons.star : Icons.star_border,
                  color: c.isFavorite
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () async {
                  await context.read<SpendlyProvider>().updateCategory(
                        c.copyWith(isFavorite: !c.isFavorite),
                      );
                },
              ),
              const Icon(Icons.edit),
            ],
          ),
          onTap: () => _showCategoryDialog(existing: c),
        );
      },
    );
  }
}
