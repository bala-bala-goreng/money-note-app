import 'package:flutter/material.dart';

/// Predefined icon names that map to Material Icons.
/// Used when creating/editing categories.
/// Add more as needed - must match Icons.xxx (camelCase).
const List<String> predefinedIconNames = [
  'restaurant',      // Food
  'local_gas_station', // Transport
  'home',            // Housing
  'shopping_cart',   // Shopping
  'fitness_center',  // Health
  'school',          // Education
  'work',            // Salary/Work
  'account_balance', // Banking
  'card_giftcard',   // Gifts
  'savings',         // Savings
  'receipt_long',    // Bills
  'flight',          // Travel
  'sports_esports',  // Entertainment
  'pets',            // Pets
  'payments',        // General payment
  'attach_money',    // Money
  'trending_up',     // Investment
  'category',        // Other
];

/// Get IconData from icon name string.
/// Falls back to Icons.category if name not found.
IconData getIconData(String iconName) {
  switch (iconName) {
    case 'restaurant': return Icons.restaurant;
    case 'local_gas_station': return Icons.local_gas_station;
    case 'home': return Icons.home;
    case 'shopping_cart': return Icons.shopping_cart;
    case 'fitness_center': return Icons.fitness_center;
    case 'school': return Icons.school;
    case 'work': return Icons.work;
    case 'account_balance': return Icons.account_balance;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'savings': return Icons.savings;
    case 'receipt_long': return Icons.receipt_long;
    case 'flight': return Icons.flight;
    case 'sports_esports': return Icons.sports_esports;
    case 'pets': return Icons.pets;
    case 'payments': return Icons.payments;
    case 'attach_money': return Icons.attach_money;
    case 'trending_up': return Icons.trending_up;
    case 'category': return Icons.category;
    default: return Icons.category;
  }
}
