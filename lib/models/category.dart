/// Represents a category for income or expense transactions.
/// Each category has a name and a predefined icon (from Material Icons).
class Category {
  final int? id; // null when creating new, set by database
  final String name;
  final String iconName; // e.g. 'food', 'shopping' - maps to Icons.xxx
  final bool isIncome; // true = income category, false = expense category
  final bool isFavorite; // when true, appears first in category lists
  final double? monthlyBudget; // optional monthly budget (mainly for expense categories)

  const Category({
    this.id,
    required this.name,
    required this.iconName,
    required this.isIncome,
    this.isFavorite = false,
    this.monthlyBudget,
  });

  /// Convert from database row (Map) to Category object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      isIncome: (map['is_income'] as int) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble(),
    );
  }

  /// Convert to Map for saving to database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_name': iconName,
      'is_income': isIncome ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'monthly_budget': monthlyBudget,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? iconName,
    bool? isIncome,
    bool? isFavorite,
    double? monthlyBudget,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isIncome: isIncome ?? this.isIncome,
      isFavorite: isFavorite ?? this.isFavorite,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
