// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/shapes/bottom_notch_rect_border.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/token_card_builder.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/components/twitter_badge.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class FeedProfileActionToken extends HookConsumerWidget {
  const FeedProfileActionToken({
    required this.externalAddress,
    this.hasNotch = false,
    this.pnl,
    this.hodl,
    this.sidePadding,
    super.key,
  });

  final String externalAddress;

  final Widget? pnl;

  final Widget? hodl;

  final double? sidePadding;

  final bool hasNotch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TokenCardBuilder(
      externalAddress: externalAddress,
      skeleton: const _Skeleton(),
      builder: (token, colors) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding ?? 16.0.s),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: BottomNotchRectBorder(
                  notchPosition: hasNotch ? NotchPosition.top : NotchPosition.none,
                ),
              ),
              child: ProfileBackground(
                colors: useImageColors(token.imageUrl),
                child: SizedBox(
                  width: double.infinity,
                  child: ProfileTokenHeaderLandscape(
                    token: token,
                    externalAddress: externalAddress,
                    pnl: pnl,
                    hodl: hodl,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileTokenHeaderLandscape extends StatelessWidget {
  const ProfileTokenHeaderLandscape({
    required this.token,
    required this.externalAddress,
    this.pnl,
    this.hodl,
    super.key,
  });

  final CommunityToken token;
  final String externalAddress;

  final Widget? pnl;

  final Widget? hodl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.all(16.0.s),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TokenAvatar(
                        imageSize: Size.square(52.s),
                        containerSize: Size.square(62.s),
                        outerBorderRadius: 16.0.s,
                        innerBorderRadius: 10.0.s,
                        imageUrl: token.imageUrl,
                        borderWidth: 2.s,
                      ),
                      if (token.source.isTwitter)
                        PositionedDirectional(
                          bottom: -3.s,
                          end: -3.s,
                          child: TwitterBadge(
                            iconSize: 12.0.s,
                            padding: EdgeInsets.all(3.s),
                            borderRadius: 5.0.s,
                            border: Border.all(color: context.theme.appColors.secondaryBackground),
                            iconColor: context.theme.appColors.secondaryBackground,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    width: 12.s,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                token.title,
                                style: context.theme.appTextThemes.subtitle3.copyWith(
                                  color: context.theme.appColors.secondaryBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (token.creator.verified.falseOrValue)
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 5.0.s),
                                child: Assets.svg.iconBadgeVerify.icon(
                                  size: 16.s,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: 9.s,
                        ),
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            vertical: 1.s,
                            horizontal: 4.s,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.theme.appColors.secondaryBackground.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.0.s),
                          ),
                          child: Text(
                            prefixUsername(
                              username: token.marketData.ticker ?? '',
                              context: context,
                            ),
                            style: context.theme.appTextThemes.caption2.copyWith(
                              color: context.theme.appColors.attentionBlock,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 12.s,
                  ),
                  if (pnl != null) pnl!,
                ],
              ),
              SizedBox(height: 16.0.s),
              Container(
                decoration: BoxDecoration(
                  color: context.theme.appColors.secondaryBackground.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10.0.s),
                ),
                padding: EdgeInsetsDirectional.only(
                  top: 14.s,
                  bottom: 14.s,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 44.s,
                  children: [
                    TokenStatItem(
                      icon: Assets.svg.iconMemeMarketcap,
                      text: MarketDataFormatter.formatCompactNumber(
                        token.marketData.marketCap,
                      ),
                    ),
                    TokenStatItem(
                      icon: Assets.svg.iconMemeMarkers,
                      text: MarketDataFormatter.formatPrice(
                        token.marketData.priceUSD,
                      ),
                    ),
                    TokenStatItem(
                      icon: Assets.svg.iconSearchGroups,
                      text: token.marketData.holders.toString(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hodl != null) hodl!,
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsetsDirectional.symmetric(horizontal: 16.s),
      padding: EdgeInsetsDirectional.symmetric(vertical: 11.s, horizontal: 14.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Column(
        children: [
          Skeleton(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 54.s,
                      width: 54.s,
                      decoration: BoxDecoration(
                        color: context.theme.appColors.attentionBlock,
                        borderRadius: BorderRadius.circular(12.0.s),
                      ),
                    ),
                    SizedBox(width: 8.s),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 115.s,
                          height: 19.s,
                          decoration: BoxDecoration(
                            color: context.theme.appColors.attentionBlock,
                            borderRadius: BorderRadius.circular(16.0.s),
                          ),
                        ),
                        SizedBox(height: 8.s),
                        Container(
                          width: 66.s,
                          height: 16.s,
                          decoration: BoxDecoration(
                            color: context.theme.appColors.attentionBlock,
                            borderRadius: BorderRadius.circular(16.0.s),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 80.s,
                      height: 26.s,
                      decoration: BoxDecoration(
                        color: context.theme.appColors.attentionBlock,
                        borderRadius: BorderRadius.circular(6.0.s),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 11.s),
          Container(
            width: 311.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.onPrimaryAccent,
              borderRadius: BorderRadius.circular(10.0.s),
            ),
            padding: EdgeInsetsDirectional.symmetric(
              vertical: 16.s,
            ),
            child: Skeleton(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 15.s,
                        width: 64.s,
                        decoration: BoxDecoration(
                          color: context.theme.appColors.attentionBlock,
                          borderRadius: BorderRadius.circular(12.0.s),
                        ),
                      ),
                      SizedBox(width: 24.s),
                      Container(
                        height: 15.s,
                        width: 64.s,
                        decoration: BoxDecoration(
                          color: context.theme.appColors.attentionBlock,
                          borderRadius: BorderRadius.circular(12.0.s),
                        ),
                      ),
                      SizedBox(width: 24.s),
                      Container(
                        height: 15.s,
                        width: 64.s,
                        decoration: BoxDecoration(
                          color: context.theme.appColors.attentionBlock,
                          borderRadius: BorderRadius.circular(12.0.s),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.s),
          Skeleton(
            child: Container(
              height: 16.s,
              width: 114.s,
              decoration: BoxDecoration(
                color: context.theme.appColors.attentionBlock,
                borderRadius: BorderRadius.circular(16.0.s),
              ),
            ),
          ),
          SizedBox(height: 10.s),
        ],
      ),
    );
  }
}
