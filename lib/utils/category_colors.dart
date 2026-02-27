import 'package:flutter/material.dart';

/// Enum-like color variants for category icons/charts.
enum CategoryColorVariant {
  red,
  purple,
  indigo,
  sky,
  teal,
  green,
  lime,
  amber,
  orange,
  brown,
  pink,
  violet,
  blueGrey,
  gray,
}

Color categoryColorFromVariant(CategoryColorVariant variant) {
  switch (variant) {
    case CategoryColorVariant.red:
      return const Color(0xFFEF5350);
    case CategoryColorVariant.purple:
      return const Color(0xFFAB47BC);
    case CategoryColorVariant.indigo:
      return const Color(0xFF5C6BC0);
    case CategoryColorVariant.sky:
      return const Color(0xFF29B6F6);
    case CategoryColorVariant.teal:
      return const Color(0xFF26A69A);
    case CategoryColorVariant.green:
      return const Color(0xFF66BB6A);
    case CategoryColorVariant.lime:
      return const Color(0xFFD4E157);
    case CategoryColorVariant.amber:
      return const Color(0xFFFFCA28);
    case CategoryColorVariant.orange:
      return const Color(0xFFFFA726);
    case CategoryColorVariant.brown:
      return const Color(0xFF8D6E63);
    case CategoryColorVariant.pink:
      return const Color(0xFFEC407A);
    case CategoryColorVariant.violet:
      return const Color(0xFF7E57C2);
    case CategoryColorVariant.blueGrey:
      return const Color(0xFF607D8B);
    case CategoryColorVariant.gray:
      return Colors.grey;
  }
}

CategoryColorVariant categoryColorVariantByIconName(String? iconName) {
  switch (iconName) {
    case 'restaurant':
      return CategoryColorVariant.orange;
    case 'local_gas_station':
      return CategoryColorVariant.indigo;
    case 'home':
      return CategoryColorVariant.brown;
    case 'shopping_cart':
      return CategoryColorVariant.pink;
    case 'fitness_center':
      return CategoryColorVariant.red;
    case 'school':
      return CategoryColorVariant.sky;
    case 'work':
      return CategoryColorVariant.blueGrey;
    case 'account_balance':
      return CategoryColorVariant.teal;
    case 'card_giftcard':
      return CategoryColorVariant.purple;
    case 'savings':
      return CategoryColorVariant.green;
    case 'receipt_long':
      return CategoryColorVariant.violet;
    case 'flight':
      return CategoryColorVariant.sky;
    case 'sports_esports':
      return CategoryColorVariant.lime;
    case 'pets':
      return CategoryColorVariant.amber;
    case 'payments':
      return CategoryColorVariant.red;
    case 'attach_money':
      return CategoryColorVariant.green;
    case 'trending_up':
      return CategoryColorVariant.teal;
    case 'movie':
      return CategoryColorVariant.purple;
    case 'medical_services':
      return CategoryColorVariant.red;
    case 'wifi':
      return CategoryColorVariant.indigo;
    default:
      return CategoryColorVariant.gray;
  }
}

Color categoryColorByIconName(String? iconName) {
  return categoryColorFromVariant(categoryColorVariantByIconName(iconName));
}
