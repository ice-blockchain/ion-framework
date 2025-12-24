// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';

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
}
