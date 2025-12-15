// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_content_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_twitter_token.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_holder_position_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_type_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_balance.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_chart.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_hodl.dart';
import 'package:ion/app/utils/num.dart';

class CommunityTokenActionBody extends HookConsumerWidget {
  const CommunityTokenActionBody({
    required this.entity,
    this.network = false,
    this.sidePadding,
    super.key,
  });

  final double? sidePadding;

  final CommunityTokenActionEntity entity;

  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionEntity = ref
        .watch(
          ionConnectEntityProvider(
            eventReference: entity.data.definitionReference,
          ),
        )
        .valueOrNull as CommunityTokenDefinitionEntity?;

    final externalAddress = definitionEntity?.data.externalAddress;

    if (externalAddress == null) {
      return const SizedBox.shrink();
    }

    final tokenMarketInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

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
            externalAddress,
            ReplaceableEventReference(
              masterPubkey: entity.masterPubkey,
              kind: UserMetadataEntity.kind,
            ).toString(),
          ),
        )
        .valueOrNull;

    final tokenType = ref.watch(tokenTypeProvider(externalAddress)).valueOrNull;

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding ?? 16.0.s),
              child: ProfileBalance(
                height: topContainerHeight,
                coins: entity.data.amount,
                amount: entity.data.amountPriceUsd,
              ),
            ),
            SizedBox(height: padding),
            if (tokenType != null)
              if (tokenType == CommunityContentTokenType.twitter)
                FeedTwitterToken(
                  externalAddress: externalAddress,
                )
              else if (tokenType == CommunityContentTokenType.profile)
                FeedProfileToken(
                  externalAddress: externalAddress,
                )
              else
                FeedContentToken(
                  externalAddress: externalAddress,
                  type: tokenType,
                  showBuyButton: false,
                  pnl: ProfileChart(
                    amount: position?.pnl ?? 0,
                  ),
                  hodl:
                      entity.data.type == CommunityTokenActionType.sell && definitionEntity != null
                          ? ProfileHODL(
                              actionEntity: entity,
                            )
                          : null,
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
    );
  }
}
