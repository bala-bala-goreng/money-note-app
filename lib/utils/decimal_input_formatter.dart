import 'package:flutter/services.dart';

/// Restricts input to numbers with at most one decimal point and max [decimalPlaces] after the dot.
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalPlaces;

  DecimalInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = newText.split('.');
    if (parts.length > 2) {
      newText = '${parts[0]}.${parts[1]}';
    }
    if (parts.length == 2 && parts[1].length > decimalPlaces) {
      newText = '${parts[0]}.${parts[1].substring(0, decimalPlaces)}';
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
