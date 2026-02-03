// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';

typedef SupplyAbbreviator = String Function(num value);
typedef UsdFormatter = String Function(double value);

String defaultAbbreviate(num value) => NumberFormat.compact(locale: 'en_US').format(value);

String defaultUsd(double value) =>
    NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2).format(value);

String defaultUsdCompact(double value) =>
    NumberFormat.compactCurrency(locale: 'en_US', symbol: r'$', decimalDigits: 1).format(value);
