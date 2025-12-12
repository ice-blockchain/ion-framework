// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_holder_position_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/community_token_image.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_balance.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_chart.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_hodl.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/username.dart';

class CommunityTokenActionBody extends HookConsumerWidget {
  const CommunityTokenActionBody({
    required this.entity,
    this.network = false,
    super.key,
  });

  final CommunityTokenActionEntity entity;

  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionEntity = ref
        .watch(ionConnectEntityProvider(eventReference: entity.data.definitionReference))
        .valueOrNull as CommunityTokenDefinitionEntity?;

    final tokenAddress = definitionEntity?.data.tokenAddress;

    if (tokenAddress == null) {
      return const SizedBox.shrink();
    }

    final tokenMarketInfo = ref.watch(tokenMarketInfoProvider(tokenAddress)).valueOrNull;

    final tokenImageUrl = tokenMarketInfo?.imageUrl;

    final avatarColors = useImageColors(tokenImageUrl);

    final topContainerHeight = 52.0.s;
    final padding = 16.0.s;
    final badgeHeight = 32.0.s;

    final type = entity.data.type == CommunityTokenActionType.buy
        ? ProfileChartType.raising
        : ProfileChartType.falling;
    final badgeColor = switch (type) {
      ProfileChartType.raising => context.theme.appColors.success,
      ProfileChartType.falling => context.theme.appColors.attentionRed,
    };

    final position = ref
        .watch(
          tokenHolderPositionProvider(
            tokenAddress,
            ReplaceableEventReference(
              masterPubkey: entity.masterPubkey,
              kind: UserMetadataEntity.kind,
            ).toString(),
          ),
        )
        .valueOrNull;

    return SizedBox(
      height: 242.s,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                ProfileBalance(
                  height: topContainerHeight,
                  coins: entity.data.amount,
                  amount: entity.data.amountPriceUsd,
                ),
                SizedBox(height: padding),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0.s),
                  child: ProfileBackground(
                    colors: avatarColors,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0.s, horizontal: 16.0.s),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CommunityTokenImage(
                                imageUrl: tokenImageUrl,
                                width: 62.0.s,
                                height: 62.0.s,
                                innerBorderRadius: 12.0.s,
                                outerBorderRadius: 16.0.s,
                                innerPadding: 2.0.s,
                              ),
                              SizedBox(width: 12.0.s),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tokenMarketInfo?.title ?? '',
                                      style: context.theme.appTextThemes.subtitle3.copyWith(
                                        color: context.theme.appColors.secondaryBackground,
                                      ),
                                    ),
                                    SizedBox(height: 8.0.s),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.0.s,
                                        vertical: 2.0.s,
                                      ),
                                      decoration: ShapeDecoration(
                                        color: context.theme.appColors.primaryBackground
                                            .withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6.0.s),
                                        ),
                                      ),
                                      child: Text(
                                        prefixUsername(
                                          username: tokenMarketInfo?.marketData.ticker,
                                          context: context,
                                        ),
                                        style: context.theme.appTextThemes.caption2.copyWith(
                                          color: context.theme.appColors.secondaryBackground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (position != null)
                                ProfileChart(
                                  amount: position.pnl,
                                  type: type,
                                ),
                            ],
                          ),
                          SizedBox(height: 16.0.s),
                          ProfileTokenStatsInfo(
                            externalAddress: tokenAddress,
                          ),
                          SizedBox(height: 10.0.s),
                          if (definitionEntity != null)
                            ProfileHODL(
                              definitionEntity: definitionEntity,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              top: topContainerHeight - (badgeHeight - padding) / 2,
              height: badgeHeight,
              child: Container(
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0.s),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 22.0.s),
                  decoration: ShapeDecoration(
                    color: badgeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9.0.s),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tokenMarketInfo?.marketData.priceUSD != null
                        ? formatToCurrency(tokenMarketInfo!.marketData.priceUSD)
                        : '',
                    style: context.theme.appTextThemes.caption2.copyWith(
                      color: context.theme.appColors.primaryBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
