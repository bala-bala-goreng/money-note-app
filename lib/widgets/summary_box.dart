import 'package:flutter/material.dart';

/// A summary card showing a single value (Expense, Balance, or Income).
/// Reusable widget - used 3 times on the dashboard.
class SummaryBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color amountColor; // Red for expense, green for income, neutral for balance

  const SummaryBox({
    super.key,
    required this.title,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
