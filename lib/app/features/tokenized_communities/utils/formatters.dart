// SPDX-License-Identifier: ice License 1.0

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
