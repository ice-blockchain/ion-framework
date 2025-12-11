// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/position_formatters.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class PostTokenButton extends ConsumerWidget {
  const PostTokenButton({
    required this.eventReference,
    this.padding,
    super.key,
  });

  final EventReference eventReference;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity =
        ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference)).valueOrNull;

    if (entity == null) {
      return const _RocketIcon();
    }

    final externalAddress = entity.toEventReference().toString();

    final isCommunityTokenEntity =
        entity is CommunityTokenDefinitionEntity || entity is CommunityTokenActionEntity;

    // We don't need token info in case of community token entities
    final tokenInfo = !isCommunityTokenEntity
        ? ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull
        : null;

    final hasToken = tokenInfo != null;

    return GestureDetector(
      onTap: () {
        isCommunityTokenEntity || hasToken
            ? TokenizedCommunityRoute(externalAddress: externalAddress).push<void>(context)
            : SwapCoinsRoute().push<void>(context);
      },
      child: Container(
        constraints: BoxConstraints(minWidth: 50.0.s),
        padding: padding,
        alignment: AlignmentDirectional.center,
        child: isCommunityTokenEntity || !hasToken
            ? const _RocketIcon()
            : _MarketCap(marketCap: tokenInfo.marketData.marketCap),
      ),
    );
  }
}

class _RocketIcon extends StatelessWidget {
  const _RocketIcon();

  @override
  Widget build(BuildContext context) {
    return Assets.svg.iconMessageMeme.icon(
      size: 16.0.s,
    );
  }
}

class _MarketCap extends StatelessWidget {
  const _MarketCap({required this.marketCap});

  final double marketCap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Assets.svg.iconMemeMarketcap.icon(
          size: 16.0.s,
          color: context.theme.appColors.onTertiaryBackground,
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.0.s),
          child: Text(
            defaultUsdCompact(marketCap),
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.onTertiaryBackground,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
