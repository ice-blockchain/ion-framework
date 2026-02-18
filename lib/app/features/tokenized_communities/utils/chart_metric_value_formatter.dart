// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/utils/formatters.dart';
import 'package:ion/app/utils/num.dart';

/// Formats a numeric value for chart display (title, tooltip, Y-axis).
///
/// Rules:
/// - `abs(value) >= 1000` -> grouped integer (e.g. `6,380`)
/// - `abs(value) >= 100`  -> grouped 2-decimal (e.g. `914.73`)
/// - `abs(value) >= 0.001` or zero -> 4-decimal fixed (e.g. `0.0300`)
/// - `abs(value) < 0.001` -> Unicode subscript notation (e.g. `0.0₄56`)
String formatChartMetricValue(double value) {
  final abs = value.abs();

  if (abs >= 1000) {
    return formatDouble(
      value,
      maximumFractionDigits: 0,
      minimumFractionDigits: 0,
    );
  }

  if (abs >= 100) {
    return formatDouble(
      value,
      // ignore: avoid_redundant_argument_values
      maximumFractionDigits: 2,
      // ignore: avoid_redundant_argument_values
      minimumFractionDigits: 2,
    );
  }

  if (abs >= 0.001 || abs == 0) {
    return value.toStringAsFixed(4);
  }

  return formatSubscriptNotation(value, keepTrailingZeros: true);
}
