import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';
import '../providers/spendly_provider.dart';
import '../models/recurring_transaction.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../utils/currency_helper.dart';

/// Root layout: bottom nav with Home, Calendar, Settings.
/// Add transaction is on the Home screen via FAB.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _navItems = [
    (icon: Icons.home, label: 'Home'),
    (icon: Icons.calendar_month, label: 'Report'),
    (icon: Icons.settings, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRecurringReminders());
  }

  Future<void> _checkRecurringReminders() async {
    await context.read<SpendlyProvider>().loadAll();
    if (!mounted) return;
    final due = await context.read<SpendlyProvider>().getDueRecurringReminders();
    if (!mounted || due.isEmpty) return;
    _showReminderDialog(due);
  }

  void _showReminderDialog(List<RecurringTransaction> due) {
    final provider = context.read<SpendlyProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 48),
        title: const Text('Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You haven\'t added or paid these yet this month:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...due.map((r) {
              final cat = provider.getCategoryById(r.categoryId);
              final label = r.description.isNotEmpty ? r.description : (cat?.name ?? '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      getIconData(cat?.iconName ?? 'category'),
                      size: 24,
                      color: categoryColorByIconName(cat?.iconName),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            formatAmountShort(r.amount),
                            style: TextStyle(
                              color: r.isIncome ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    onSaved: () => Navigator.pop(context),
                  ),
                ),
              ).then((_) {
                if (mounted) context.read<SpendlyProvider>().loadAll();
              });
            },
            child: const Text('Add now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          CalendarScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _navItems
            .map((e) => NavigationDestination(
                  icon: Icon(e.icon),
                  selectedIcon: Icon(e.icon, fill: 1),
                  label: e.label,
                ))
            .toList(),
      ),
    );
  }
}
