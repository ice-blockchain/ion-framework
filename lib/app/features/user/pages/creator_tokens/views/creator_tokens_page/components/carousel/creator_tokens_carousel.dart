// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensCarousel extends HookConsumerWidget {
  const CreatorTokensCarousel({
    required this.tokens,
    required this.onItemChanged,
    super.key,
  });

  static const _carouselHeight = 303.0;
  static const _carouselHorizontalPadding = 24.0;

  final List<CommunityToken> tokens;
  final void Function(CommunityToken) onItemChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CarouselSlider.builder(
      options: CarouselOptions(
        height: _carouselHeight.s,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        onPageChanged: (index, _) => onItemChanged(tokens[index]),
      ),
      itemCount: tokens.length,
      itemBuilder: (context, index, realIndex) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _carouselHorizontalPadding.s),
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

  static const _topPadding = 23.0;

  final CommunityToken token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = token.creator.avatar;
    final colors = useImageColors(avatarUrl);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0.s),
      ),
      clipBehavior: Clip.antiAlias,
      child: ProfileBackground(
        key: ValueKey(token.externalAddress),
        colors: colors,
        child: Padding(
          padding: EdgeInsets.only(top: _topPadding.s),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.0.s),
                  color: context.theme.appColors.primaryBackground,
                ),
                padding: EdgeInsets.all(2.0.s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0.s),
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          width: 98.0.s,
                          height: 98.0.s,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 98.0.s,
                            height: 98.0.s,
                            color: context.theme.appColors.tertiaryBackground,
                          ),
                        )
                      : Container(
                          width: 98.0.s,
                          height: 98.0.s,
                          color: context.theme.appColors.tertiaryBackground,
                        ),
                ),
              ),
              SizedBox(height: 20.0.s),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        token.creator.display,
                        style: context.theme.appTextThemes.subtitle.copyWith(
                          color: context.theme.appColors.secondaryBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (token.creator.verified) ...[
                        SizedBox(width: 4.0.s),
                        Assets.svg.iconBadgeVerify.icon(
                          size: 16.0.s,
                          color: context.theme.appColors.secondaryBackground,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.0.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '@${token.creator.name}',
                        style: context.theme.appTextThemes.body2.copyWith(
                          color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(width: 8.0.s),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
                        decoration: BoxDecoration(
                          color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0.s),
                        ),
                        child: Text(
                          MarketDataFormatter.formatPrice(token.marketData.priceUSD),
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: context.theme.appColors.secondaryBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.0.s),
              _CreatorStatsWidget(
                marketCap: token.marketData.marketCap,
                volume: token.marketData.volume,
                holders: token.marketData.holders,
              ),
            ],
          ),
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
    final color = context.theme.appColors.secondaryBackground;
    final iconColorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    final textStyle = context.theme.appTextThemes.caption2.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );

    final stats = [
      (icon: Assets.svg.iconMemeMarketcap, value: formatCount(marketCap.toInt())),
      (icon: Assets.svg.iconMemeMarkers, value: formatCount(volume.toInt())),
      (icon: Assets.svg.iconSearchGroups, value: formatCount(holders)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 6.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in stats) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  item.icon,
                  colorFilter: iconColorFilter,
                  height: 12.0.s,
                  width: 12.0.s,
                ),
                SizedBox(height: 2.0.s),
                Text(item.value, style: textStyle),
              ],
            ),
            if (item != stats.last) SizedBox(width: 16.0.s),
          ],
        ],
      ),
    );
  }
}
