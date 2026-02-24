import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/money_note_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_helper.dart';
import 'category_management_screen.dart';

/// Settings: General (currency, categories), Data (reset, export, import), About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionLabel('General'),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => ListTile(
              title: const Text('Currency'),
              subtitle: Text(settings.currencyCode),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCurrencyPicker(context, settings),
            ),
          ),
          ListTile(
            title: const Text('Category management'),
            subtitle: const Text('Add or edit categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementScreen(),
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionLabel('Data'),
          ListTile(
            title: const Text('Reset data'),
            subtitle: const Text('Clear all transactions and categories'),
            trailing: const Icon(Icons.delete_outline),
            onTap: () => _confirmReset(context),
          ),
          ListTile(
            title: const Text('Export data'),
            subtitle: const Text('Save a copy of the database'),
            trailing: const Icon(Icons.upload_file),
            onTap: () => _exportData(context),
          ),
          ListTile(
            title: const Text('Import data'),
            subtitle: const Text('Restore from a backup file'),
            trailing: const Icon(Icons.download),
            onTap: () => _importData(context),
          ),
          const Divider(height: 1),
          const _SectionLabel('About'),
          const ListTile(
            title: Text('Money Note'),
            subtitle: Text('Track income and expenses. Data stays on your device.'),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: Text('1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const ListTile(
            title: Text('Created by'),
            subtitle: Text('perutkentang.developer'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Reset data?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'This will delete all transactions and categories and restore default categories. This cannot be undone.',
            ),
            SizedBox(height: 16),
            SelectableText(
              'Warning: Make sure you know what you are doing. You can lose your data.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && context.mounted) {
        await context.read<MoneyNoteProvider>().resetData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data reset'), backgroundColor: Colors.green),
          );
        }
      }
    });
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      String? dirPath;
      if (Platform.isAndroid || Platform.isIOS) {
        dirPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose folder to save export',
        );
      }
      if (!context.mounted) return;
      final path = await context.read<MoneyNoteProvider>().exportData(
        targetDirectoryPath: dirPath,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $path'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Import data?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'This will replace your current data with the backup file you select. Current data cannot be recovered.',
            ),
            SizedBox(height: 16),
            SelectableText(
              'Warning: Make sure you know what you are doing. You can lose your data.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
        return;
      }
      final path = result.files.single.path!;
      await context.read<MoneyNoteProvider>().importData(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ...supportedCurrencies.map((code) {
              final selected = settings.currencyCode == code;
              return ListTile(
                title: Text(code),
                trailing: selected ? const Icon(Icons.check, color: Colors.teal) : null,
                onTap: () {
                  settings.setCurrency(code);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
