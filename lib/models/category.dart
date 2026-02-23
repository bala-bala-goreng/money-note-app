/// Represents a category for income or expense transactions.
/// Each category has a name and a predefined icon (from Material Icons).
class Category {
  final int? id; // null when creating new, set by database
  final String name;
  final String iconName; // e.g. 'food', 'shopping' - maps to Icons.xxx
  final bool isIncome; // true = income category, false = expense category

  const Category({
    this.id,
    required this.name,
    required this.iconName,
    required this.isIncome,
  });

  /// Convert from database row (Map) to Category object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      isIncome: (map['is_income'] as int) == 1,
    );
  }

  /// Convert to Map for saving to database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_name': iconName,
      'is_income': isIncome ? 1 : 0,
    };
  }

  Category copyWith({int? id, String? name, String? iconName, bool? isIncome}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
