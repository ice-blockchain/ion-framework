// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/utils/num.dart';

String formatApproxUSD(double amount, String Function(String) approximate) =>
    amount > minDisplayUSD ? approximate(formatUSD(amount)) : formatToCurrency(amount);
