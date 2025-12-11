// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';

String formatPercent(double p) {
  final sign = p >= 0 ? '+' : '';
  return '$sign${p.toStringAsFixed(2)}%';
}

String formatPrice(double price, {String symbol = r'$'}) {
  if (price >= 1) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(price);
  }
  // Handle small prices with subscript notation similar to PriceLabelFormatter
  final abs = price.abs();
  if (abs == 0) return r'$0.00';

  final expStr = abs.toStringAsExponential(12);
  final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
  if (match == null) {
    return NumberFormat.currency(symbol: r'$', decimalDigits: 4).format(price);
  }

  final mantissaStr = match.group(1)!;
  final exponent = int.parse(match.group(2)!);

  if (exponent >= -1) {
    return NumberFormat.currency(symbol: r'$', decimalDigits: 4).format(price);
  }

  final digits = mantissaStr.replaceAll('.', '');
  final trailing = digits.isEmpty ? '0' : (digits.length >= 3 ? digits.substring(0, 3) : digits);

  return '\$0.0₄$trailing';
}

// Formats a DateTime for chart date labels (e.g., "15/03").
String formatChartDate(DateTime date) {
  return DateFormat('dd/MM').format(date);
}

// Formats a DateTime for chart time labels (e.g., "14:30").
String formatChartTime(DateTime date) {
  return DateFormat('H:mm').format(date);
}
