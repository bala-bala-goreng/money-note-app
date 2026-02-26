/// Reminder timing for monthly recurring transactions.
enum ReminderType {
  none,
  endMonthMinus3, // End of month - 3 days
  startMonthPlus3, // Start of month + 3 days (1st to 3rd)
}

/// A recurring transaction template.
/// Used to quick-fill the add transaction form.
class RecurringTransaction {
  final int? id;
  final int categoryId;
  final String description;
  final double amount;
  final bool isIncome;
  final bool isReminderEnabled;
  final ReminderType reminderType;

  const RecurringTransaction({
    this.id,
    required this.categoryId,
    required this.description,
    required this.amount,
    required this.isIncome,
    this.isReminderEnabled = false,
    this.reminderType = ReminderType.none,
  });

  static ReminderType _reminderTypeFromString(String? s) {
    switch (s) {
      case 'end_month_minus_3':
        return ReminderType.endMonthMinus3;
      case 'start_month_plus_3':
        return ReminderType.startMonthPlus3;
      default:
        return ReminderType.none;
    }
  }

  /// True if [date] falls within the reminder window for [type].
  static bool isInReminderWindow(ReminderType type, DateTime date) {
    if (type == ReminderType.none) return false;
    final day = date.day;
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    switch (type) {
      case ReminderType.endMonthMinus3:
        return day >= lastDay - 2; // last 3 days of month
      case ReminderType.startMonthPlus3:
        return day <= 3; // 1st, 2nd, 3rd
      case ReminderType.none:
        return false;
    }
  }

  static String? _reminderTypeToString(ReminderType t) {
    switch (t) {
      case ReminderType.endMonthMinus3:
        return 'end_month_minus_3';
      case ReminderType.startMonthPlus3:
        return 'start_month_plus_3';
      case ReminderType.none:
        return null;
    }
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final isReminder = (map['is_reminder'] as int?) == 1;
    return RecurringTransaction(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      isIncome: (map['is_income'] as int) == 1,
      isReminderEnabled: isReminder,
      reminderType: isReminder
          ? _reminderTypeFromString(map['reminder_type'] as String?)
          : ReminderType.none,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'description': description,
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'is_reminder': isReminderEnabled ? 1 : 0,
      'reminder_type': _reminderTypeToString(reminderType),
    };
  }

  RecurringTransaction copyWith({
    int? id,
    int? categoryId,
    String? description,
    double? amount,
    bool? isIncome,
    bool? isReminderEnabled,
    ReminderType? reminderType,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderType: reminderType ?? this.reminderType,
    );
  }
}
