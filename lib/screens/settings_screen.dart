import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/spendly_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_helper.dart';
import 'category_management_screen.dart';
import 'recurring_transaction_screen.dart';

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
          ListTile(
            title: const Text('Manage recurring transaction'),
            subtitle: const Text('Income and expense templates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecurringTransactionScreen(),
              ),
            ),
          ),
          const Divider(height: 1),
          const _SectionLabel('Data'),
          ListTile(
            title: const Text('Reset data'),
            subtitle: const Text('Delete all transactions and categories'),
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
            title: Text('Spendly'),
            subtitle: Text('Track income and expenses. Data stays on your device.'),
          ),
          _VersionTile(onSeedTestData: _confirmSeedTestData),
          const ListTile(
            title: Text('Created by'),
            subtitle: Text('perutkentang.developer'),
          ),
          ListTile(
            title: const Text('Support developer'),
            subtitle: const Text('saweria.co/perutkentang'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _launchSaweria(context),
          ),
        ],
      ),
    );
  }

  void _confirmSeedTestData(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Seed test data?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              'Existing data will be replaced with sample data. Use this to test all features (Dashboard, Report, Recurring, Reminder).',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed data'),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && context.mounted) {
        await context.read<SpendlyProvider>().seedTestData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test data seeded successfully'), backgroundColor: Colors.green),
          );
        }
      }
    });
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
        await context.read<SpendlyProvider>().resetData();
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
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dirPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose folder to save export',
        );
      }
      if (!context.mounted) return;
      final path = await context.read<SpendlyProvider>().exportData(
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
      await context.read<SpendlyProvider>().importData(path);
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

  static Future<void> _launchSaweria(BuildContext context) async {
    final uri = Uri.parse('https://saweria.co/perutkentang');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
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

/// Version row: tap 10x to seed test data. Ada animasi klik sebagai feedback.
class _VersionTile extends StatefulWidget {
  final void Function(BuildContext context) onSeedTestData;

  const _VersionTile({required this.onSeedTestData});

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  Timer? _resetTimer;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    _resetTimer?.cancel();
    _animController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _animController.reverse();
    _tapCount++;
    if (_tapCount >= 10) {
      _tapCount = 0;
      widget.onSeedTestData(context);
    } else {
      _resetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _tapCount = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: ListTile(
            title: const Text('Version'),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
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
