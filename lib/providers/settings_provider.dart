import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_helper.dart';

const _keyCurrency = 'currency_code';

/// Holds app settings (currency) and persists them.
class SettingsProvider extends ChangeNotifier {
  String _currencyCode = 'IDR';

  String get currencyCode => _currencyCode;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_keyCurrency) ?? 'IDR';
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (!supportedCurrencies.contains(code)) return;
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, code);
    notifyListeners();
  }

  String formatAmount(double amount) => formatCurrency(amount, _currencyCode);
}
