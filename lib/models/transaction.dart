/// Represents a single income or expense transaction.
/// Stored in SQLite with references to category.
/// List is ordered by transactionDate first, then createdAt.
class TransactionRecord {
  final int? id;
  final String description;
  final double amount; // Always positive; type determined by category
  final int categoryId;
  /// User-picked date (for display and primary sort).
  final DateTime transactionDate;
  /// When the record was created (for secondary sort).
  final DateTime createdAt;
  final bool isIncome; // true = income, false = expense

  const TransactionRecord({
    this.id,
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.transactionDate,
    required this.createdAt,
    required this.isIncome,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      transactionDate: map['transaction_date'] != null
          ? DateTime.parse(map['transaction_date'] as String)
          : DateTime.parse(map['created_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      isIncome: (map['is_income'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'amount': amount,
      'category_id': categoryId,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_income': isIncome ? 1 : 0,
    };
  }
}
