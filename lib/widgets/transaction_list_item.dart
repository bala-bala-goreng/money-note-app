import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/category_colors.dart';
import '../utils/category_icons.dart';
import '../providers/settings_provider.dart';

/// Single row in the transaction list.
/// Shows: category (with icon), description, amount on the right.
/// Amount color: red for expense, green for income.
class TransactionListItem extends StatelessWidget {
  final TransactionRecord transaction;
  final Category? category;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.isIncome ? Colors.green : Colors.red;
    final iconColor = categoryColorByIconName(category?.iconName);
    final formattedAmount = context.read<SettingsProvider>().formatAmount(transaction.amount);
    final dateStr = DateFormat('d MMM y').format(transaction.transactionDate);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.2),
        child: Icon(
          category != null ? getIconData(category!.iconName) : Icons.receipt,
          color: iconColor,
        ),
      ),
      title: Text(
        category?.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$dateStr · ${transaction.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formattedAmount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
    );
  }
}
