// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class FeedTwitterTokenAction extends HookConsumerWidget {
  const FeedTwitterTokenAction({
    required this.externalAddress,
    this.pnl,
    this.hodl,
    super.key,
  });

  final String externalAddress;
  final Widget? pnl;
  final Widget? hodl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;
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
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12.s, 16.s, 10.s, 16.s),
                child: Column(
                  children: [
                    TwitterTokenHeader(
                      token: token,
                      pnl: pnl,
                      hodl: hodl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TwitterTokenHeader extends StatelessWidget {
  const TwitterTokenHeader({
    required this.token,
    this.showBuyButton = true,
    this.pnl,
    this.hodl,
    super.key,
  });

  final CommunityToken token;
  final bool showBuyButton;
  final Widget? pnl;
  final Widget? hodl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                TokenAvatar(
                  imageSize: Size.square(54.s),
                  containerSize: Size.square(62.s),
                  outerBorderRadius: 16.0.s,
                  innerBorderRadius: 16.0.s,
                  imageUrl: token.imageUrl,
                  borderWidth: 2.s,
                ),
                PositionedDirectional(
                  bottom: -3.s,
                  end: -3.s,
                  child: Container(
                    padding: EdgeInsets.all(3.58.s),
                    decoration: BoxDecoration(
                      color: const Color(0xff1D1E20),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(6.0.s),
                    ),
                    child: Assets.svg.iconLoginXlogo.icon(
                      size: 12.0.s,
                      color: context.theme.appColors.secondaryBackground,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.0.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      token.title,
                      style: context.theme.appTextThemes.subtitle3.copyWith(
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
                SizedBox(height: 8.0.s),
                Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    vertical: 1.s,
                    horizontal: 4.s,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.appColors.secondaryBackground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.0.s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        prefixUsername(
                          username: token.marketData.ticker ?? '',
                          context: context,
                        ),
                        style: context.theme.appTextThemes.caption2.copyWith(
                          color: context.theme.appColors.attentionBlock,
                        ),
                      ),
                      SizedBox(
                        width: 6.s,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (pnl != null) pnl!,
          ],
        ),
        SizedBox(height: 16.s),
        Container(
          decoration: BoxDecoration(
            color: context.theme.appColors.secondaryBackground.withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(16.0.s),
          ),
          padding: EdgeInsetsDirectional.only(
            top: 18.s,
            bottom: 18.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 25.s,
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
        if (hodl != null) hodl!,
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        top: 16.0.s,
        bottom: 10.s,
        start: 16.s,
        end: 16.s,
      ),
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
            child: Row(
              children: [
                Container(
                  height: 62.s,
                  width: 62.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                ),
                SizedBox(width: 12.s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16.s,
                      width: 138.s,
                      decoration: BoxDecoration(
                        color: context.theme.appColors.attentionBlock,
                        borderRadius: BorderRadius.circular(16.0.s),
                      ),
                    ),
                    SizedBox(height: 8.s),
                    Container(
                      height: 16.s,
                      width: 66.s,
                      decoration: BoxDecoration(
                        color: context.theme.appColors.attentionBlock,
                        borderRadius: BorderRadius.circular(16.0.s),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 26.s,
                  width: 80.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(7.0.s),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.s),
          Container(
            width: 288.s,
            height: 66.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.onPrimaryAccent,
              borderRadius: BorderRadius.circular(16.0.s),
            ),
            child: Skeleton(
              child: Column(
                children: [
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
          SizedBox(height: 10.s),
          Skeleton(
            child: Container(
              width: 72.s,
              height: 23.s,
              decoration: BoxDecoration(
                color: context.theme.appColors.attentionBlock,
                borderRadius: BorderRadius.circular(16.0.s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
