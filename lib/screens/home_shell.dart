import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import '../providers/money_note_provider.dart';

/// Root layout: bottom nav with Dashboard (left), Add (middle), Settings (right).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _navItems = [
    (icon: Icons.home, label: 'Home'),
    (icon: Icons.add_circle_outline, label: 'Add'),
    (icon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardScreen(),
          AddTransactionScreen(
            onSaved: () => setState(() => _currentIndex = 0),
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<MoneyNoteProvider>().loadAll();
            });
          }
        },
        destinations: _navItems
            .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
            .toList(),
      ),
    );
  }
}
