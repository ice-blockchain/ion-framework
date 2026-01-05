// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';

class MarketDataFormatter {
  MarketDataFormatter._();

  // Formats a large number into a compact string representation.
  // - 1234 -> 1.23K
  // - 1234567 -> 1.23M
  // - 1234567890 -> 1.23B
  static String formatCompactNumber(num value) {
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(2)}K';
    } else if (value < 1) {
      return value.toStringAsFixed(2);
    }

    return value.toStringAsFixed(0);
  }

  // Formats a USD price value.
  // - 123.45 -> $123.45
  // - 0.123 -> $0.12
  static String formatPrice(double value, {String symbol = r'$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(value);
  }

  // Formats a USD volume value with $ prefix.
  // - 2961.69 -> $2.96K
  // - 3000000 -> $3.00M
  static String formatVolume(double volume) {
    return r'$' + formatCompactNumber(volume);
  }

  // Formats a USD amount with compact notation for large values or subscript for small values.
  // All values include symbol prefix (default: $).
  // - Zero: "$0" (e.g., "$0")
  // - Small values (< 0.01): subscript notation with symbol (e.g., "$0.00₂25")
  // - Medium values (0.01 to < 1.0): price format with decimals (e.g., "$0.88")
  // - Large values (>= 1.0): compact notation with symbol (e.g., "$2.96K", "$1.23M")
  static String formatCompactOrSubscript(double value, {String symbol = r'$'}) {
    final absValue = value.abs();

    if (absValue == 0) {
      return '${symbol}0';
    }

    // For very small values, use subscript notation with symbol prefix
    if (absValue < 0.01) {
      final subscriptResult = formatSubscriptNotation(value, symbol);
      if (subscriptResult.isEmpty) {
        // Fallback to price format for edge cases
        return formatPrice(value, symbol: symbol);
      }
      return subscriptResult;
    }

    // For values between 0.01 and 1.0, use price format with decimals
    if (absValue < 1.0) {
      return formatPrice(value, symbol: symbol);
    }

    // For large values (>= 1.0), use compact notation with symbol prefix
    return '$symbol${formatCompactNumber(value)}';
  }
}
