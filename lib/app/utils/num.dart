// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';

String formatDouble(
  double value, {
  int maximumFractionDigits = 2,
  int minimumFractionDigits = 2,
}) {
  final formatter = NumberFormat.decimalPattern('en_US')
    ..maximumFractionDigits = maximumFractionDigits
    ..minimumFractionDigits = minimumFractionDigits;
  return formatter.format(value);
}

/// A number format for compact representations, e.g. "1.2M" instead
/// of "1,200,000".
String formatDoubleCompact(num value) {
  return NumberFormat.compact().format(value);
}

String formatToCurrency(double value, [String? symbol]) {
  return NumberFormat.currency(symbol: symbol ?? r'$', decimalDigits: 2).format(value);
}

String formatUSD(double usdAmount) => NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    ).format(usdAmount);

String formatCount(int number) {
  if (number >= 10000) {
    return NumberFormat.compact(locale: 'en_US').format(number);
  } else {
    return NumberFormat('#,##0', 'en_US').format(number);
  }
}
