// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';

String? amountValidator({
  required String? value,
  required BuildContext context,
  double? maxValue,
  CoinData? coin,
  String? insufficientFundsError,
  int? decimalsForNetwork,
}) {
  final locale = context.i18n;

  final trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty) return null;

  final parsed = parseAmount(trimmedValue);
  if (parsed == null) return '';

  if (maxValue != null && (parsed > maxValue || parsed < 0)) {
    return insufficientFundsError ?? locale.wallet_coin_amount_insufficient_funds;
  } else if (parsed < 0) {
    return locale.wallet_coin_amount_must_be_positive;
  } else if (coin != null || decimalsForNetwork != null) {
    final decimals = decimalsForNetwork ?? coin?.decimals;
    final amount = toBlockchainUnits(parsed, decimals ?? 0);
    if (amount == BigInt.zero && parsed > 0) {
      return locale.wallet_coin_amount_too_low_for_sending;
    }
  }

  return null;
}
