import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/money_note_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MoneyNoteApp());
}

/// Root widget. Wrap app in ChangeNotifierProvider so any screen can
/// access MoneyNoteProvider via `context.read<MoneyNoteProvider>()`.
class MoneyNoteApp extends StatelessWidget {
  const MoneyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoneyNoteProvider(),
      child: MaterialApp(
        title: 'Money Note',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
