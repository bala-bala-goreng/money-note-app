import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_note_provider.dart';
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

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoneyNoteProvider>().loadAll();
    });
  }

  void _showCategoryDialog({Category? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String iconName = existing?.iconName ?? 'category';
    bool isIncome = existing?.isIncome ?? true;

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
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Income')),
                    ButtonSegment(value: false, label: Text('Expense')),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (s) =>
                      setState(() => isIncome = s.first),
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
                final cat = Category(
                  id: existing?.id,
                  name: name.trim(),
                  iconName: iconName,
                  isIncome: isIncome,
                );
                final provider = context.read<MoneyNoteProvider>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Consumer<MoneyNoteProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet. Tap + to add.'));
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
                subtitle: Text(c.isIncome ? 'Income' : 'Expense'),
                trailing: const Icon(Icons.edit),
                onTap: () => _showCategoryDialog(existing: c),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
