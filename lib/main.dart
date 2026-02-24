import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/money_note_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const MoneyNoteApp());
}

/// Root widget. Providers for data and settings; home is the bottom-nav shell.
class MoneyNoteApp extends StatelessWidget {
  const MoneyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyNoteProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Money Note',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const HomeShell(),
      ),
    );
  }
}
