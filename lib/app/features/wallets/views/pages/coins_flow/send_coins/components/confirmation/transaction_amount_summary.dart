// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';

class TransactionAmountSummary extends StatelessWidget {
  const TransactionAmountSummary({
    required this.amount,
    required this.currency,
    required this.usdAmount,
    required this.icon,
    required this.transactionType,
    this.isFailed = false,
    super.key,
  });

  final double amount;
  final String currency;
  final double usdAmount;
  final Widget icon;
  final TransactionType transactionType;
  final bool isFailed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 8.0.s),
            Text(
              '${transactionType.sign}${formatCrypto(amount, currency)}',
              style: textTheme.headline2.copyWith(
                color: transactionType == TransactionType.receive && !isFailed
                    ? colors.success
                    : colors.primaryText,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.0.s),
        Text(
          context.i18n.wallet_approximate_in_usd(
            formatUSD(usdAmount),
          ),
          style: textTheme.caption2.copyWith(
            color: colors.secondaryText,
          ),
        ),
      ],
    );
  }
}
