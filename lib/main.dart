import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/spendly_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const SpendlyApp());
}

/// Root widget. Providers for data and settings; home is the bottom-nav shell.
class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpendlyProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Spendly',
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
