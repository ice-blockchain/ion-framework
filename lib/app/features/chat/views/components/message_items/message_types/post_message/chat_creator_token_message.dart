// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/dividers/gradient_horizontal_divider.dart';
import 'package:ion/app/components/dividers/gradient_vertical_divider.dart';
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
      skeleton: const _LoadingSkeleton(),
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
                                  token.marketData.marketCap,
                                ),
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

    final color = context.theme.appColors.primaryBackground;

    final isLoading = followListAsync.isLoading || followersCountAsync.isLoading;
    if (!isLoading && !bothAvailable) {
      return const SizedBox.shrink();
    }

    return Row(
      spacing: 2.0.s,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FollowType.following.iconAsset.icon(
          size: 16.0.s,
          color: color,
        ),
        SizedBox(width: 1.0.s),
        Text(
          formatCount(followingNumber ?? 0),
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 1.0.s),
        Text(
          FollowType.following.getTitle(context),
          style: context.theme.textTheme.bodySmall?.copyWith(color: color),
        ),
        SizedBox(width: 2.0.s),
        const GradientVerticalDivider(),
        SizedBox(width: 2.0.s),
        FollowType.followers.iconAsset.icon(
          size: 16.0.s,
          color: context.theme.appColors.primaryBackground,
        ),
        SizedBox(width: 1.0.s),
        Text(
          formatCount(followersNumber ?? 0),
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 1.0.s),
        Text(
          FollowType.followers.getTitle(context),
          style: context.theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// A more accurate skeleton loading state matching ChatCreatorTokenMessage dimensions.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0.s),
        child: ColoredBox(
          color: context.theme.appColors.tertiaryBackground,
          child: Column(
            children: [
              SizedBox(height: 24.0.s),
              // Avatar skeleton - matches 88.s container
              Skeleton(
                baseColor: context.theme.appColors.attentionBlock,
                child: Container(
                  height: 88.s,
                  width: 88.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(21.0.s),
                  ),
                ),
              ),
              SizedBox(height: 8.0.s),
              // Title skeleton
              Skeleton(
                baseColor: context.theme.appColors.attentionBlock,
                child: Container(
                  height: 20.s,
                  width: 140.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(10.0.s),
                  ),
                ),
              ),
              SizedBox(height: 4.0.s),
              // Username and price skeleton
              Skeleton(
                baseColor: context.theme.appColors.attentionBlock,
                child: Container(
                  height: 16.s,
                  width: 110.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.attentionBlock,
                    borderRadius: BorderRadius.circular(8.0.s),
                  ),
                ),
              ),
              SizedBox(height: 14.0.s),
              // Stats container skeleton - matches the Container with margin 30.s
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30.0.s),
                padding: EdgeInsets.symmetric(vertical: 15.s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.0.s),
                  color: context.theme.appColors.onPrimaryAccent.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    // Follow counters skeleton
                    Skeleton(
                      baseColor: context.theme.appColors.attentionBlock,
                      child: Container(
                        height: 14.s,
                        width: 180.s,
                        decoration: BoxDecoration(
                          color: context.theme.appColors.attentionBlock,
                          borderRadius: BorderRadius.circular(7.0.s),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.0.s),
                    // Divider
                    Container(
                      height: 1.s,
                      margin: EdgeInsets.symmetric(horizontal: 20.0.s),
                      color: context.theme.appColors.attentionBlock.withValues(alpha: 0.2),
                    ),
                    SizedBox(height: 12.0.s),
                    // Stats row skeleton
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItemSkeleton(),
                        _StatItemSkeleton(),
                        _StatItemSkeleton(),
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
    );
  }
}

/// Skeleton for individual stat items
class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      baseColor: context.theme.appColors.attentionBlock,
      child: Column(
        children: [
          Container(
            height: 16.s,
            width: 16.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.attentionBlock,
              borderRadius: BorderRadius.circular(4.0.s),
            ),
          ),
          SizedBox(height: 4.s),
          Container(
            height: 12.s,
            width: 45.s,
            decoration: BoxDecoration(
              color: context.theme.appColors.attentionBlock,
              borderRadius: BorderRadius.circular(6.0.s),
            ),
          ),
        ],
      ),
    );
  }
}
