// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

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

  // Always show exactly 2 decimals (truncated, no rounding) for amount >= 1,
  // including when whole < 1000 (e.g. 1.00, 999.92).
  final thousand = BigInt.from(1000);
  if (whole < thousand) {
    final frac2 = ((amount % divisor) * BigInt.from(100)) ~/ divisor;
    final frac2Str = frac2.toString().padLeft(2, '0');
    return '$whole.$frac2Str';
  }

  // Compact form (K, M, …) with always 2 decimals from compact remainder.
  return _formatAmountCompactWithDecimals(whole);
}

/// Formats a BigInt >= 1000 into compact form (e.g. 999.92K) with exactly 2 decimals (truncated).
String _formatAmountCompactWithDecimals(BigInt value) {
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

  final dec2 = (remainder * BigInt.from(100)) ~/ thousand;
  final frac2Str = dec2.toString().padLeft(2, '0');
  final sign = isNegative ? '-' : '';
  final suffix = suffixes[tier];
  return '$sign$current.$frac2Str$suffix';
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

  final suffix = suffixes[tier];

  // Up to 2 decimals (truncated, never rounded up).
  final dec2 = (remainder * BigInt.from(100)) ~/ thousand; // 0..99
  if (dec2 == BigInt.zero) {
    return '$sign$current$suffix';
  }

  final frac2 = dec2.toString().padLeft(2, '0');
  final trimmedFrac = frac2.replaceFirst(RegExp(r'0+$'), ''); // 1 or 2 digits

  return '$sign$current.$trimmedFrac$suffix';
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
  if (value > 0) {
    return '+';
  } else if (value < 0) {
    return '-';
  }
  return '';
}

String formatSupplySharePercent(double value, {int decimals = 2}) {
// We want *truncation* (never rounding up) to avoid values like 99.9999 -> 100.00.
// Also ensure very small positive values show at least 0.01%.
  if (!value.isFinite || value <= 0) {
    return '0.${'0' * decimals}';
  }

  const maxPercent = 100.0;
  final factor = math.pow(10, decimals).toInt();

// Cap at 100.00% (in case of tiny floating overshoots).
  if (value >= maxPercent) {
    return formatScaledInt((maxPercent * factor).round(), factor, decimals);
  }

// Truncate instead of round.
  final scaled = (value * factor + 1e-9).floor();

// Ensure a minimum display of 0.01% for any positive value that would truncate to 0.00.
  final safeScaled = scaled == 0 ? 1 : scaled;

  return formatScaledInt(safeScaled, factor, decimals);
}

String formatScaledInt(int scaled, int factor, int decimals) {
  final whole = scaled ~/ factor;
  final frac = scaled % factor;
  return '$whole.${frac.toString().padLeft(decimals, '0')}';
}
