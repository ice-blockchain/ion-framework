// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class FeedProfileToken extends HookConsumerWidget {
  const FeedProfileToken({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token =
        ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    if (token == null) {
      return _Skeleton();
    }

    final colors = useImageColors(token.imageUrl);

    if (colors == null) {
      return _Skeleton();
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 16.0.s,
          end: 16.0.s,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0.s),
          child: ProfileBackground(
            colors: useImageColors(token.imageUrl),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: 24.0.s),
                  ProfileTokenHeader(
                    token: token,
                    externalAddress: externalAddress,
                  ),
                  SizedBox(height: 34.s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileTokenHeader extends StatelessWidget {
  const ProfileTokenHeader({
    required this.token,
    required this.externalAddress,
    this.minimal = false,
    super.key,
  });

  final CommunityToken token;
  final String externalAddress;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TokenAvatar(
          imageSize: Size.square(88.s),
          containerSize: Size.square(96.s),
          outerBorderRadius: 20.0.s,
          innerBorderRadius: 16.0.s,
          imageUrl: token.imageUrl,
          borderWidth: 2.s,
        ),
        SizedBox(height: 8.0.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              token.title,
              style: context.theme.appTextThemes.subtitle.copyWith(
                color: context.theme.appColors.secondaryBackground,
              ),
            ),
            if (token.creator.verified)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 5.0.s),
                child: Assets.svg.iconBadgeVerify.icon(
                  size: 16.s,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.0.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              prefixUsername(
                username: token.marketData.ticker ?? '',
                context: context,
              ),
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.attentionBlock,
              ),
            ),
            SizedBox(
              width: 6.s,
            ),
            ProfileTokenPrice(amount: token.marketData.priceUSD),
          ],
        ),
        SizedBox(height: 16.0.s),
        if (minimal)
          IntrinsicWidth(
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.appColors.secondaryBackground.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(16.0.s),
              ),
              padding: EdgeInsetsDirectional.only(
                top: 14.s,
                bottom: 14.s,
                start: 30.s,
                end: 30.s,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32.s,
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
                    text: MarketDataFormatter.formatCompactNumber(
                      token.marketData.volume,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(27.s, 0.s, 27.s, 0.s),
            child: ProfileTokenStatsFeed(
              externalAddress: externalAddress,
            ),
          ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 24.0.s),
      margin: EdgeInsetsDirectional.symmetric(horizontal: 16.0.s),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      child: Column(
        children: [
          Skeleton(
            baseColor: context.theme.appColors.attentionBlock,
            child: Column(
              children: [
                Container(
                  height: 96.s,
                  width: 96.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(24.0.s),
                  ),
                ),
                SizedBox(height: 8.s),
                Container(
                  height: 20.s,
                  width: 123.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                ),
                SizedBox(height: 4.s),
                Container(
                  height: 18.s,
                  width: 92.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.s),
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 288.s,
                height: 98.s,
                decoration: BoxDecoration(
                  color: context.theme.appColors.onPrimaryAccent,
                  borderRadius: BorderRadius.circular(16.0.s),
                ),
                child: Skeleton(
                  child: Column(
                    children: [
                      SizedBox(height: 16.s),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 15.s,
                            width: 97.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 97.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.s),
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
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              color: context.theme.appColors.attentionBlock,
                              borderRadius: BorderRadius.circular(12.0.s),
                            ),
                          ),
                          SizedBox(width: 13.s),
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
              Positioned(
                bottom: -11.5.s,
                child: Skeleton(
                  baseColor: context.theme.appColors.attentionBlock,
                  child: Container(
                    width: 72.s,
                    height: 23.s,
                    decoration: BoxDecoration(
                      color: context.theme.appColors.attentionBlock,
                      borderRadius: BorderRadius.circular(16.0.s),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 34.0.s),
        ],
      ),
    );
  }
}
