import 'package:intl/intl.dart';

/// Supported currency codes. IDR = no decimals; others use 2.
const List<String> supportedCurrencies = ['IDR', 'USD', 'EUR'];

/// Format amount with the given currency code.
/// IDR: "IDR 10.000" (no decimals). USD/EUR: "USD 10.00"
String formatCurrency(double amount, String currencyCode) {
  final noDecimals = currencyCode == 'IDR';
  final symbol = '$currencyCode ';
  final format = NumberFormat.currency(
    locale: currencyCode == 'IDR' ? 'id_ID' : 'en_US',
    symbol: symbol,
    decimalDigits: noDecimals ? 0 : 2,
  );
  return format.format(amount);
}

/// Short format for summary boxes: K below 1M, "X.X mil" at 1M+ (e.g. 15K, 12.5K, 1.2 mil, 10.1 mil).
String formatAmountShort(double amount) {
  final sign = amount < 0 ? '-' : '';
  final n = amount.abs();
  if (n >= 1_000_000) {
    final mil = n / 1_000_000;
    final s = mil == mil.roundToDouble()
        ? '${mil.toInt()} mil'
        : '${mil.toStringAsFixed(1)} mil';
    return sign + s;
  }
  if (n >= 1000) {
    final k = n / 1000;
    final s = k == k.roundToDouble() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    return sign + s;
  }
  final s = n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
  return sign + s;
}
