// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';
import 'package:ion/app/features/tokenized_communities/models/chart_data.dart';
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
    return NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 2).format(price);
  }
  // Handle small prices with subscript notation
  final abs = price.abs();
  if (abs == 0) return '${symbol}0.00';

  final expStr = abs.toStringAsExponential(12);
  final match = RegExp(r'^(\d(?:\.\d+)?)e([+-]\d+)$').firstMatch(expStr);
  if (match == null) {
    return NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 4).format(price);
  }

  final mantissaStr = match.group(1)!;
  final exponent = int.parse(match.group(2)!);

  if (exponent >= -1) {
    return NumberFormat.currency(locale: 'en_US', symbol: symbol, decimalDigits: 4).format(price);
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

// Formats a DateTime for chart axis labels based on time range.
// Uses dd/MM for 1d interval, H:mm for all others.
String formatChartAxisLabel(DateTime date, ChartTimeRange range) {
  return range == ChartTimeRange.d1 ? formatChartDate(date) : formatChartTime(date);
}
