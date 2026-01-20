// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_price_label.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_type_gradient_indicator.dart';
import 'package:ion/app/features/tokenized_communities/views/components/twitter_badge.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensListItem extends HookConsumerWidget {
  const CreatorTokensListItem({
    required this.token,
    required this.index,
    super.key,
  });

  final CommunityToken token;
  final int index;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        ref
            .read(cachedTokenMarketInfoNotifierProvider(token.externalAddress).notifier)
            .cacheToken(token);

        TokenizedCommunityRoute(
          externalAddress: token.externalAddress,
        ).push<void>(context);
      },
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: index == 0 ? 12.0.s : 6.0.s, bottom: 6.0.s),
        child: Row(
          children: [
            Stack(
              alignment: AlignmentDirectional.bottomEnd,
              clipBehavior: Clip.none,
              children: [
                TokenAvatar(
                  imageUrl: token.imageUrl,
                  containerSize: Size.square(30.s),
                  imageSize: Size.square(30.s),
                  outerBorderRadius: 10.s,
                  innerBorderRadius: 10.s,
                  borderWidth: 0,
                  enablePaletteGenerator: false,
                ),
                if (token.source.isTwitter)
                  PositionedDirectional(
                    bottom: 0.s,
                    end: -6.s,
                    child: TwitterBadge(
                      iconSize: 8.0.s,
                      padding: EdgeInsets.all(2.s),
                      iconColor: context.theme.appColors.secondaryBackground,
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
                children: [
                  Text(
                    token.title,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.appTextThemes.subtitle3,
                    strutStyle: const StrutStyle(forceStrutHeight: true),
                  ),
                  _CreatorStatsWidget(
                    marketCap: token.marketData.marketCap,
                    volume: token.marketData.volume,
                    holders: token.marketData.holders,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.0.s),
            TokenPriceLabel(
              text: formatPriceWithSubscript(token.marketData.priceUSD),
              textStyle: context.theme.appTextThemes.caption4.copyWith(
                color: context.theme.appColors.primaryBackground,
                fontWeight: FontWeight.bold,
              ),
              height: 20.0.s,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorStatsWidget extends StatelessWidget {
  const _CreatorStatsWidget({
    required this.marketCap,
    required this.volume,
    required this.holders,
  });

  final double marketCap;
  final double volume;
  final int holders;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.appColors.quaternaryText;
    final iconColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    final textStyle = context.theme.appTextThemes.caption.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );

    final stats = [
      (
        icon: Assets.svg.iconMemeMarketcap,
        value: MarketDataFormatter.formatCompactNumber(marketCap)
      ),
      (icon: Assets.svg.iconMemeMarkers, value: MarketDataFormatter.formatVolume(volume)),
      (
        icon: Assets.svg.iconSearchGroups,
        value: formatCount(holders),
      ),
    ];

    return Row(
      children: [
        for (final item in stats) ...[
          SvgPicture.asset(
            item.icon,
            colorFilter: iconColorFilter,
            height: 14.0.s,
            width: 14.0.s,
          ),
          SizedBox(width: 2.0.s),
          Text(item.value, style: textStyle),
          if (item != stats.last) ...[
            SizedBox(width: 6.0.s),
            Text('•', style: textStyle),
            SizedBox(width: 6.0.s),
          ],
        ],
      ],
    );
  }
}
