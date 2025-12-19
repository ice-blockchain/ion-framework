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

/// Formats a raw integer string that represents a fixed-decimal amount (e.g. wei)
/// into a compact, human-friendly string.
///
/// Default `decimals` is 18 (common for ERC-20 style tokens).
String formatAmountCompactFromRaw(String raw, {int decimals = 18}) {
  final v = raw.trim();
  final amount = BigInt.tryParse(v);
  if (amount == null) return raw;

  final divisor = BigInt.from(10).pow(decimals);
  final whole = amount ~/ divisor;

  if (whole == BigInt.zero) {
    // Show up to 4 fractional digits for small values (< 1 token)
    final frac = (amount % divisor).toString().padLeft(decimals, '0');
    final trimmed = frac.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return '0';
    final shown = trimmed.length <= 4 ? trimmed : trimmed.substring(0, 4);
    return '0.$shown';
  }

  // Use our truncating compact formatter to avoid rounding up (e.g. 999,928 -> 999K, not 1M).
  return formatBigIntCompact(whole);
}

/// Formats a BigInt into a compact representation: 12.3K, 4.5M, 6.7B, etc.
/// This is base-1000 and avoids floating point math.
String formatBigIntCompact(BigInt value) {
  final isNegative = value.isNegative;
  var current = value.abs();

  const suffixes = <String>['', 'K', 'M', 'B', 'T', 'Q', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];
  final thousand = BigInt.from(1000);

  var tier = 0;
  var remainder = BigInt.zero;

  while (current >= thousand && tier < suffixes.length - 1) {
    remainder = current % thousand;
    current = current ~/ thousand;
    tier++;
  }

  final sign = isNegative ? '-' : '';

  if (tier == 0) {
    return '$sign$current';
  }

  final dec = (remainder * BigInt.from(10)) ~/ thousand;
  final withDec =
      (dec > BigInt.zero && current < BigInt.from(100)) ? '$current.$dec' : current.toString();

  return '$sign$withDec${suffixes[tier]}';
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

String getNumericSign(num value) {
  if (value >= 0) {
    return '+';
  } else {
    return '-';
  }
}
