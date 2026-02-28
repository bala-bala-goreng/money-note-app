import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/spendly_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_helper.dart';
import '../database/database_helper.dart';
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
            title: const Text('Manage frequently transaction'),
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
          ListTile(
            title: const Text('Upload backup to Google Drive'),
            subtitle: const Text('Export then share to Google Drive'),
            trailing: const Icon(Icons.cloud_upload_outlined),
            onTap: () => _uploadBackupToGoogleDrive(context),
          ),
          ListTile(
            title: const Text('Import backup from Google Drive'),
            subtitle: const Text('Pick a .db backup from Google Drive'),
            trailing: const Icon(Icons.cloud_download_outlined),
            onTap: () => _importFromGoogleDrive(context),
          ),
          const Divider(height: 1),
          const _SectionLabel('About'),
          const ListTile(
            title: Text('Spendly'),
            subtitle: Text('Track income and expenses. Data stays on your device.'),
          ),
          _VersionTile(onSwitchDatabase: _switchDatabaseFromVersionTap),
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

  Future<void> _switchDatabaseFromVersionTap(BuildContext context) async {
    final provider = context.read<SpendlyProvider>();
    final switchedToTest = await provider.toggleActiveDatabase();
    if (switchedToTest && provider.transactions.isEmpty) {
      await provider.seedTestData();
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switchedToTest
              ? 'Switched to TEST database (${DatabaseHelper.testDbFileName})'
              : 'Switched to MAIN database (${DatabaseHelper.primaryDbFileName})',
        ),
        backgroundColor: Colors.green,
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
        type: FileType.any,
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
      if (!path.toLowerCase().endsWith('.db')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .db backup file')),
          );
        }
        return;
      }
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

  Future<void> _uploadBackupToGoogleDrive(BuildContext context) async {
    try {
      final path = await context.read<SpendlyProvider>().exportData();
      final file = XFile(path);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: 'Spendly backup database',
          title: 'Upload backup',
        ),
      );
      if (context.mounted) {
        final ok = result.status == ShareResultStatus.success;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Backup shared. Choose Google Drive to upload.'
                  : 'Share was cancelled or unavailable on this device',
            ),
            backgroundColor: ok ? Colors.green : null,
          ),
        );
      }
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share plugin is not ready. Please restart the app and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importFromGoogleDrive(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Import from Google Drive?'),
        content: const SelectableText(
          'Select a .db backup file from Google Drive. This will replace your current data.',
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
        dialogTitle: 'Pick backup from Google Drive',
        type: FileType.any,
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
      if (!path.toLowerCase().endsWith('.db')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .db backup file')),
          );
        }
        return;
      }
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
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
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

/// Version row: tap 10x to switch active database (main/test).
class _VersionTile extends StatefulWidget {
  final Future<void> Function(BuildContext context) onSwitchDatabase;

  const _VersionTile({required this.onSwitchDatabase});

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
      await widget.onSwitchDatabase(context);
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
            subtitle: Consumer<SpendlyProvider>(
              builder: (context, provider, _) => Text(
                '1.0.0 • ${provider.isUsingTestDatabase ? 'TEST DB' : 'MAIN DB'}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
