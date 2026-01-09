// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/token_card_builder.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_price.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/followers_count_provider.r.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class ChatCreatorTokenMessage extends HookConsumerWidget {
  const ChatCreatorTokenMessage({required this.externalAddress, super.key});

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TokenCardBuilder(
      skeleton: _LoadingSkeleton(),
      externalAddress: externalAddress,
      builder: (token, colors) {
        return SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0.s),
            child: ProfileBackground(
              colors: (first: colors.first, second: colors.second),
              child: SizedBox(
                child: Column(
                  children: [
                    SizedBox(height: 24.0.s),
                    TokenAvatar(
                      borderWidth: 2.s,
                      imageUrl: token.imageUrl,
                      outerBorderRadius: 21.0.s,
                      innerBorderRadius: 17.0.s,
                      imageSize: Size.square(82.s),
                      containerSize: Size.square(88.s),
                      borderColor: context.theme.appColors.primaryBackground,
                    ),
                    SizedBox(height: 8.0.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          token.title,
                          style: context.theme.appTextThemes.subtitle.copyWith(
                            color: context.theme.appColors.primaryBackground,
                          ),
                        ),
                        if (token.creator.verified.falseOrValue)
                          Padding(
                            padding: EdgeInsetsDirectional.only(start: 5.0.s),
                            child: Assets.svg.iconBadgeVerify.icon(size: 16.s),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.0.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          prefixUsername(
                            context: context,
                            username: token.marketData.ticker ?? '',
                          ),
                          style: context.theme.appTextThemes.caption.copyWith(
                            color: context.theme.appColors.primaryBackground,
                          ),
                        ),
                        SizedBox(width: 6.s),
                        ProfileTokenPrice(amount: token.marketData.priceUSD),
                      ],
                    ),
                    SizedBox(height: 14.0.s),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30.0.s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11.0.s),
                        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
                      ),
                      padding: EdgeInsetsDirectional.only(
                        top: 15.s,
                        bottom: 15.s,
                      ),
                      child: Column(
                        children: [
                          if (token.addresses.ionConnect != null)
                            _FollowCounters(
                              masterPubkey:
                                  ReplaceableEventReference.fromString(token.addresses.ionConnect!)
                                      .masterPubkey,
                            ),
                          GradientHorizontalDivider(margin: EdgeInsets.symmetric(vertical: 12.0.s)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TokenStatItem(
                                icon: Assets.svg.iconMemeMarketcap,
                                text: MarketDataFormatter.formatCompactNumber(
                                    token.marketData.marketCap),
                              ),
                              TokenStatItem(
                                icon: Assets.svg.iconMemeMarkers,
                                text: MarketDataFormatter.formatVolume(token.marketData.volume),
                              ),
                              TokenStatItem(
                                icon: Assets.svg.iconSearchGroups,
                                text: formatCount(token.marketData.holders),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.s),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FollowCounters extends ConsumerWidget {
  const _FollowCounters({required this.masterPubkey});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followListAsync = ref.watch(followListProvider(masterPubkey));
    final followersCountAsync = ref.watch(followersCountProvider(masterPubkey));
    final followingNumber = followListAsync.valueOrNull?.data.list.length;
    final followersNumber = followersCountAsync.valueOrNull;
    final bothAvailable = followingNumber != null && followersNumber != null;

    final isLoading = followListAsync.isLoading || followersCountAsync.isLoading;
    if (!isLoading && !bothAvailable) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FollowType.following.iconAsset.icon(
                  size: 16.0.s,
                  color: context.theme.appColors.primaryBackground,
                ),
                SizedBox(width: 2.0.s),
                Text(
                  formatCount(followingNumber ?? 0),
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.theme.appColors.primaryBackground,
                  ),
                ),
                SizedBox(width: 2.0.s),
                Text(
                  FollowType.following.getTitle(context),
                  style: context.theme.textTheme.bodySmall?.copyWith(
                    color: context.theme.appColors.primaryBackground,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FollowType.followers.iconAsset.icon(
              size: 16.0.s,
              color: context.theme.appColors.primaryBackground,
            ),
            SizedBox(width: 2.0.s),
            Text(
              formatCount(followersNumber ?? 0),
              style: context.theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.theme.appColors.primaryBackground,
              ),
            ),
            SizedBox(width: 2.0.s),
            Text(
              FollowType.followers.getTitle(context),
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.theme.appColors.primaryBackground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 24.0.s),
      margin: EdgeInsetsDirectional.symmetric(horizontal: 16.0.s),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0.s),
        color: context.theme.appColors.tertiaryBackground,
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
                              borderRadius: BorderRadius.circular(12.0.s),
                              color: context.theme.appColors.primaryBackground,
                            ),
                          ),
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0.s),
                              color: context.theme.appColors.primaryBackground,
                            ),
                          ),
                          SizedBox(width: 13.s),
                          Container(
                            height: 15.s,
                            width: 64.s,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0.s),
                              color: context.theme.appColors.primaryBackground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
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
