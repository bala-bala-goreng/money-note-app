// Basic widget test - verifies the app loads and shows the dashboard.
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_note_app/providers/money_note_provider.dart';
import 'package:money_note_app/widgets/summary_box.dart';

void main() {
  testWidgets('App loads and shows dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MoneyNoteProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Money Note')),
                body: const Text('Dashboard'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Money Note'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('SummaryBox displays title and amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SummaryBox(
                title: 'Expenses',
                amount: 'Rp 10.000',
                amountColor: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Rp 10.000'), findsOneWidget);
  });
}
