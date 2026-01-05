// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart'
    as market_data_formatter;
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensCarousel extends HookConsumerWidget {
  const CreatorTokensCarousel({
    required this.tokens,
    required this.onItemChanged,
    super.key,
  });

  static const carouselHeight = 251.0;
  static const carouselHorizontalPadding = 24.0;
  static const carouselTopPadding = _CarouselCard.topPadding;

  final List<CommunityToken> tokens;
  final void Function(CommunityToken) onItemChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnInit(() {
      if (tokens.length >= 3) {
        onItemChanged(tokens[1]);
      }
    });

    return CarouselSlider.builder(
      options: CarouselOptions(
        height: carouselHeight.s,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        initialPage: tokens.length >= 3 ? 1 : 0,
        onPageChanged: (index, _) => onItemChanged(tokens[index]),
      ),
      itemCount: tokens.length,
      itemBuilder: (context, index, realIndex) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: carouselHorizontalPadding.s),
          child: _CarouselCard(token: tokens[index]),
        );
      },
    );
  }
}

class _CarouselCard extends HookConsumerWidget {
  const _CarouselCard({
    required this.token,
  });

  static const topPadding = 22.0;

  final CommunityToken token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnInit(() {
      ref
          .read(cachedTokenMarketInfoNotifierProvider(token.externalAddress).notifier)
          .cacheToken(token);
    });

    final avatarUrl = token.imageUrl;
    final colors = useImageColors(avatarUrl);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            TokenizedCommunityRoute(
              externalAddress: token.externalAddress,
            ).push<void>(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: CreatorTokensCarousel.carouselHeight.s,
            width: 205.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0.s),
            ),
            margin: EdgeInsetsDirectional.only(top: NavigationAppBar.screenHeaderHeight / 2),
            clipBehavior: Clip.antiAlias,
            child: ProfileBackground(
              key: ValueKey(token.externalAddress),
              colors: colors,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: topPadding.s + 4.s,
                ),
                child: Column(
                  children: [
                    TokenAvatar(
                      imageUrl: avatarUrl,
                      containerSize: Size.square(92.0.s),
                      imageSize: Size.square(90.0.s),
                      outerBorderRadius: 22.0.s,
                      innerBorderRadius: 22.0.s,
                      borderWidth: 2.0.s,
                      borderColor: context.theme.appColors.secondaryBackground,
                    ),
                    SizedBox(height: 10.0.s),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  token.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.theme.appTextThemes.subtitle.copyWith(
                                    color: context.theme.appColors.secondaryBackground,
                                  ),
                                ),
                              ),
                              if (token.creator.verified.falseOrValue) ...[
                                SizedBox(width: 4.0.s),
                                Assets.svg.iconBadgeVerify.icon(
                                  size: 16.0.s,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 5.0.s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '@${token.marketData.ticker}',
                                  overflow: TextOverflow.ellipsis,
                                  style: context.theme.appTextThemes.caption2.copyWith(
                                    color: context.theme.appColors.secondaryBackground,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.0.s),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
                                decoration: BoxDecoration(
                                  color: context.theme.appColors.onPrimaryAccent,
                                  borderRadius: BorderRadius.circular(7.0.s),
                                ),
                                child: Text(
                                  market_data_formatter
                                      .formatPriceWithSubscript(token.marketData.priceUSD),
                                  style: context.theme.appTextThemes.caption2.copyWith(
                                    color: context.theme.appColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0.s),
                    _CreatorStatsWidget(
                      marketCap: token.marketData.marketCap,
                      volume: token.marketData.volume,
                      holders: token.marketData.holders,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    final color = context.theme.appColors.secondaryBackground;
    final textStyle = context.theme.appTextThemes.caption3.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    final stats = [
      (
        icon: Assets.svg.iconMemeMarketcap,
        value: MarketDataFormatter.formatCompactNumber(marketCap)
      ),
      (icon: Assets.svg.iconMemeMarkers, value: MarketDataFormatter.formatVolume(volume)),
      (icon: Assets.svg.iconSearchGroups, value: formatCount(holders)),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      height: 40.s,
      padding: EdgeInsets.symmetric(horizontal: 12.0.s),
      child: Row(
        children: [
          for (final item in stats) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item.icon,
                  SizedBox(height: 1.s),
                  Text(item.value, style: textStyle),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
