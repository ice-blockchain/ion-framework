// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class UserHoldingsListItem extends StatelessWidget {
  const UserHoldingsListItem({
    required this.token,
    super.key,
  });

  final CommunityToken token;

  @override
  Widget build(BuildContext context) {
    final position = token.marketData.position;
    if (position == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(
                    size: 30.0.s,
                    imageUrl: token.imageUrl,
                    borderRadius: BorderRadius.circular(10.0.s),
                  ),
                  if (token.addresses.twitter != null)
                    Positioned(
                      left: 23.0.s,
                      top: 20.0.s,
                      child: _TwitterBadge(),
                    ),
                ],
              ),
              SizedBox(width: 8.0.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${token.title} #${position.rank}',
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Assets.svg.iconTabsCoins.icon(
                          size: 14.15.s,
                          color: context.theme.appColors.quaternaryText,
                        ),
                        SizedBox(width: 4.0.s),
                        Text(
                          formatAmountCompactFromRaw(position.amount),
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.quaternaryText,
                          ),
                        ),
                        SizedBox(width: 6.0.s),
                        Text(
                          '•',
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.quaternaryText,
                          ),
                        ),
                        SizedBox(width: 6.0.s),
                        _ProfitLossIndicator(position: position),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
          decoration: BoxDecoration(
            color: context.theme.appColors.primaryAccent,
            borderRadius: BorderRadius.circular(12.0.s),
          ),
          child: Text(
            '\$${MarketDataFormatter.formatCompactNumber(position.amountUSD)}',
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onPrimaryAccent,
              height: 16 / context.theme.appTextThemes.caption2.fontSize!,
            ),
          ),
        ),
      ],
    );
  }
}

class _TwitterBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13.0.s,
      height: 13.0.s,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E20),
        borderRadius: BorderRadius.circular(4.0.s),
      ),
      child: Center(
        child: Assets.svg.iconLoginXlogo.icon(
          size: 8.0.s,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ProfitLossIndicator extends StatelessWidget {
  const _ProfitLossIndicator({
    required this.position,
  });

  final Position position;

  @override
  Widget build(BuildContext context) {
    final isProfit = position.pnl >= 0;
    final profitColor =
        isProfit ? context.theme.appColors.success : context.theme.appColors.raspberry;

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
