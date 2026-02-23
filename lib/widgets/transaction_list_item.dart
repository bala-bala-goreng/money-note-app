import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/category_icons.dart';

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
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final amountColor = transaction.isIncome ? Colors.green : Colors.red;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.2),
        child: Icon(
          category != null ? getIconData(category!.iconName) : Icons.receipt,
          color: amountColor,
        ),
      ),
      title: Text(
        category?.name ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        currencyFormat.format(transaction.amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
      ),
    );
  }
}
