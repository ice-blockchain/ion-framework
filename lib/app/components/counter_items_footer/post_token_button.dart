// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/token_creation_not_available_modal/token_creation_not_available_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/position_formatters.dart';
import 'package:ion/app/features/tokenized_communities/utils/token_operation_restrictions.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
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
      return _TokenButtonPlaceholder(padding: padding);
    }
    return switch (entity) {
      CommunityTokenDefinitionEntity() => _TokenDefinitionButton(entity: entity, padding: padding),
      CommunityTokenActionEntity() => _TokenActionButton(entity: entity, padding: padding),
      _ => _ContentEntityButton(entity: entity, padding: padding),
    };
  }
}

class _TokenAvailability extends StatelessWidget {
  const _TokenAvailability({required this.available, required this.child});

  final bool available;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: available ? HitTestBehavior.deferToChild : HitTestBehavior.translucent,
      onTap: available
          ? null
          : () {
              showSimpleBottomSheet<void>(
                context: context,
                child: const TokenCreationNotAvailableModal(),
              );
            },
      child: IgnorePointer(
        ignoring: !available,
        child: Opacity(
          opacity: available ? 1.0 : 0.5,
          child: child,
        ),
      ),
    );
  }
}

class _TokenDefinitionButton extends StatelessWidget {
  const _TokenDefinitionButton({required this.entity, this.padding});

  final CommunityTokenDefinitionEntity entity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final route = switch (entity.data) {
      CommunityTokenDefinitionIon(:final eventReference) =>
        TokenizedCommunityRoute(externalAddress: eventReference.toString()),
      CommunityTokenDefinitionExternal(:final externalId) =>
        TokenizedCommunityRoute(externalAddress: externalId),
      _ => null,
    };
    return _TokenButton(
      padding: padding,
      onTap: route == null ? null : () => route.push<void>(context),
      child: const _RocketIcon(),
    );
  }
}

class _TokenActionButton extends ConsumerWidget {
  const _TokenActionButton({required this.entity, this.padding});

  final CommunityTokenActionEntity entity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenDefinition = ref
        .watch(ionConnectEntityProvider(eventReference: entity.data.definitionReference))
        .valueOrNull as CommunityTokenDefinitionEntity?;

    if (tokenDefinition == null) {
      return _TokenButtonPlaceholder(padding: padding);
    }

    final route = switch (tokenDefinition.data) {
      CommunityTokenDefinitionIon(:final eventReference) =>
        TokenizedCommunityRoute(externalAddress: eventReference.toString()),
      CommunityTokenDefinitionExternal(:final externalId) =>
        TokenizedCommunityRoute(externalAddress: externalId),
      _ => null,
    };

    return _TokenButton(
      padding: padding,
      onTap: route == null ? null : () => route.push<void>(context),
      child: const _RocketIcon(),
    );
  }
}

class _ContentEntityButton extends ConsumerWidget {
  const _ContentEntityButton({required this.entity, this.padding});

  final IonConnectEntity entity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventReference = entity.toEventReference();
    // Check if token operations are restricted for this account
    final isRestricted = TokenOperationRestrictions.isRestrictedAccountEvent(eventReference);
    if (isRestricted) {
      return const SizedBox.shrink();
    }

    final ownerHasBscWallet = ref
        .watch(
          userMetadataProvider(eventReference.masterPubkey)
              .select((e) => e.valueOrNull?.hasBscWallet),
        )
        .falseOrValue;
    final hasTokenDefinition = ref
        .watch(ionConnectEntityHasTokenDefinitionProvider(eventReference: eventReference))
        .valueOrNull
        .falseOrValue;
    final hasToken = ref
        .watch(ionConnectEntityHasTokenProvider(eventReference: eventReference))
        .valueOrNull
        .falseOrValue;

    final isTokenCreationAvailable = ownerHasBscWallet && hasTokenDefinition;

    final externalAddressType = entity.externalAddressType;

    return _TokenAvailability(
      available: isTokenCreationAvailable,
      child: _TokenButton(
        padding: padding,
        child:
            hasToken ? _MarketCap(externalAddress: eventReference.toString()) : const _RocketIcon(),
        onTap: () {
          if (hasToken) {
            TokenizedCommunityRoute(
              externalAddress: eventReference.toString(),
            ).push<void>(context);
          } else if (externalAddressType != null) {
            TradeCommunityTokenRoute(
              eventReference: eventReference.encode(),
            ).push<void>(context);
          }
        },
      ),
    );
  }
}

class _TokenButtonPlaceholder extends StatelessWidget {
  const _TokenButtonPlaceholder({this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return _TokenButton(padding: padding, child: const _RocketIcon());
  }
}

class _TokenButton extends StatelessWidget {
  const _TokenButton({required this.child, this.padding, this.onTap});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: 50.0.s),
        padding: padding,
        alignment: AlignmentDirectional.center,
        child: child,
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

class _MarketCap extends ConsumerWidget {
  const _MarketCap({required this.externalAddress});

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenInfo = ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull;

    if (tokenInfo == null) {
      return const _RocketIcon();
    }

    return Row(
      children: [
        Assets.svg.iconMemeMarketcap.icon(
          size: 16.0.s,
          color: context.theme.appColors.onTertiaryBackground,
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.0.s),
          child: Text(
            defaultUsdCompact(tokenInfo.marketData.marketCap),
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
