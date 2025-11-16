// SPDX-License-Identifier: ice License 1.0

import 'package:intl/intl.dart';

typedef SupplyAbbreviator = String Function(num value);
typedef UsdFormatter = String Function(double value);

String defaultAbbreviate(num value) => NumberFormat.compact().format(value);

String defaultUsd(double value) =>
    NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(value);
