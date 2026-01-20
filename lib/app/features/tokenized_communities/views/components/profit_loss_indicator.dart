// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

/// A widget that displays profit/loss indicator for a token position.
/// 
/// Shows an icon and formatted P&L amount with appropriate color:
/// - Green for profit (positive P&L)
/// - Red for loss (negative P&L)
class ProfitLossIndicator extends StatelessWidget {
  const ProfitLossIndicator({
    required this.position,
    super.key,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    final isProfit = position.pnl >= 0;
    final profitColor = isProfit
        ? context.theme.appColors.success
        : context.theme.appColors.raspberry;

    final pnlSign = getNumericSign(position.pnl);
    final pnlAmount = MarketDataFormatter.formatCompactNumber(position.pnl.abs());

    return Row(
      children: [
        Assets.svg.iconCreatecoinProfit.icon(
          size: 14.15.s,
          color: profitColor,
        ),
        SizedBox(width: 4.0.s),
        Text(
          '$pnlSign\$$pnlAmount',
          style: context.theme.appTextThemes.caption.copyWith(
            color: profitColor,
          ),
        ),
      ],
    );
  }
}
