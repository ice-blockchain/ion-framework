// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion/app/utils/num.dart';

String formatPercent(double p) {
  final sign = p > 0 ? '+' : '';
  final absP = p.abs();

  if (absP < 100) {
    // ignore: avoid_redundant_argument_values
    return '$sign${formatDouble(p, maximumFractionDigits: 2, minimumFractionDigits: 2)}%';
  } else {
    // >= 100: 0 decimals (rounded) with thousand separators
    return '$sign${formatDouble(p, maximumFractionDigits: 0, minimumFractionDigits: 0)}%';
  }
}

String formatPrice(double price, {String symbol = r'$'}) {
  if (price >= 1) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(price);
  }
  // Handle small prices with subscript notation similar to PriceLabelFormatter
  final abs = price.abs();
  if (abs == 0) return '${symbol}0.00';

  final expStr = abs.toStringAsExponential(12);
  final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
  if (match == null) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 4).format(price);
  }

  final mantissaStr = match.group(1)!;
  final exponent = int.parse(match.group(2)!);

  if (exponent >= -1) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 4).format(price);
  }

  final digits = mantissaStr.replaceAll('.', '');
  final trailing = digits.isEmpty ? '0' : (digits.length >= 3 ? digits.substring(0, 3) : digits);

  return '\$0.0₄$trailing';
}

/// Formats a price with subscript notation for very small values.
/// Examples:
/// 0.1 -> $0.1
/// 0.12 -> $0.12
/// 0.123 -> $0.123
/// 0.001 -> $0.001
/// 0.0001 -> $0.0₃1
/// 0.00001 -> $0.0₄1
String formatPriceWithSubscript(double price, {String symbol = r'$'}) {
  final absPrice = price.abs();

  if (absPrice >= 0.01) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(price);
  }

  if (absPrice >= 0.001) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 3).format(price);
  }

  if (absPrice == 0) return '${symbol}0.00';

  // For very small values, use subscript notation
  final subscriptResult = formatSubscriptNotation(price, symbol);
  if (subscriptResult.isEmpty) {
    // Fallback if subscript formatting fails
    return NumberFormat.currency(symbol: symbol, decimalDigits: 4).format(price);
  }
  return subscriptResult;
}

// Formats a value using subscript notation for very small numbers.
// Returns a string like "$0.0₂25" for very small values.
String formatSubscriptNotation(double value, String symbol) {
  final absValue = value.abs();
  final expStr = absValue.toStringAsExponential(12);
  final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
  if (match == null) {
    return '';
  }

  final mantissaStr = match.group(1)!;
  final exponent = int.parse(match.group(2)!);
  final absExponent = exponent.abs();
  final zeroCount = absExponent - 1;

  final digits = mantissaStr.replaceAll('.', '');
  // Keep at most 2 significant digits for the trailing part
  var trailing = digits.length > 2 ? digits.substring(0, 2) : digits;
  trailing = trailing.replaceAll(RegExp(r'0+$'), '');
  if (trailing.isEmpty) trailing = '0';

  final sign = value < 0 ? '-' : '';
  return '$sign$symbol' '0.0' '${toSubscript(zeroCount)}' '$trailing';
}

String toSubscript(int number) {
  final digits = number.toString();
  const subscriptMap = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
  };
  return digits.split('').map((d) => subscriptMap[d] ?? d).join();
}

// Formats a DateTime for chart date labels (e.g., "15/03").
String formatChartDate(DateTime date) {
  return DateFormat('dd/MM').format(date);
}

// Formats a DateTime for chart time labels (e.g., "14:30").
String formatChartTime(DateTime date) {
  return DateFormat('H:mm').format(date);
}

// Formats a DateTime for chart axis labels based on time range.
// Uses dd/MM for 1d interval, H:mm for all others.
String formatChartAxisLabel(DateTime date, ChartTimeRange range) {
  return range == ChartTimeRange.d1 ? formatChartDate(date) : formatChartTime(date);
}
