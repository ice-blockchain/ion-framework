// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/components/profit_loss_indicator.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_price_label.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_type_gradient_indicator.dart';
import 'package:ion/app/features/tokenized_communities/views/components/twitter_badge.dart';
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
                  TokenAvatar(
                    imageUrl: token.imageUrl,
                    containerSize: Size.square(30.0.s),
                    imageSize: Size.square(30.0.s),
                    outerBorderRadius: 10.0.s,
                    innerBorderRadius: 10.0.s,
                    borderWidth: 0,
                  ),
                  if (token.source.isTwitter)
                    PositionedDirectional(
                      start: 23.0.s,
                      top: 20.0.s,
                      child: TwitterBadge(
                        iconSize: 8.0.s,
                        iconColor: Colors.white,
                        containerSize: 13.0.s,
                      ),
                    )
                  else if (token.type != CommunityTokenType.profile)
                    PositionedDirectional(
                      end: -6.0.s,
                      bottom: -1.0.s,
                      child: TokenTypeGradientIndicator(tokenType: token.type),
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
                        ProfitLossIndicator(position: position),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        TokenPriceLabel(
          text: '\$${MarketDataFormatter.formatCompactNumber(position.amountUSD)}',
        ),
      ],
    );
  }
}
