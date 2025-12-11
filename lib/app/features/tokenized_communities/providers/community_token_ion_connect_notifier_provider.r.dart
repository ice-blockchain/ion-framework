// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_builder_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_reference_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_ion_connect_notifier_provider.r.g.dart';

@riverpod
class CommunityTokenIonConnectNotifier extends _$CommunityTokenIonConnectNotifier {
  @override
  FutureOr<String?> build(EventReference origEventReference) => null;

  // TODO:pass buy transaction data
  Future<void> sendBuyAction({
    required bool firstBuy,
  }) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);
      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
      final communityTokenDefinitionBuilder = ref.read(communityTokenDefinitionBuilderProvider);
      final communityTokenAction =
          await _buildCommunityTokenAction(type: CommunityTokenActionType.buy);
      final communityTokenFirstBuyAction = await communityTokenDefinitionBuilder.build(
        origEventReference: origEventReference,
        type: CommunityTokenDefinitionType.firstBuyAction,
      );
      final isOwnToken = ref.read(isCurrentUserSelectorProvider(origEventReference.masterPubkey));

      await Future.wait([
        ionConnectNotifier.sendEntitiesData(
          [
            communityTokenAction,
            if (firstBuy && isOwnToken) communityTokenFirstBuyAction,
          ],
          cache: false,
        ),
        if (!isOwnToken)
          ionConnectNotifier.sendEntitiesData(
            [
              communityTokenAction,
              if (firstBuy) communityTokenFirstBuyAction,
            ],
            actionSource: ActionSource.user(origEventReference.masterPubkey),
            metadataBuilders: [userEventsMetadataBuilder],
            cache: false,
          ),
      ]);

      return null;
    });
  }

  // TODO:pass sell transaction data
  Future<void> sendSellAction() async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);
      final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
      final communityTokenAction =
          await _buildCommunityTokenAction(type: CommunityTokenActionType.sell);
      final isOwnToken = ref.read(isCurrentUserSelectorProvider(origEventReference.masterPubkey));

      await Future.wait([
        ionConnectNotifier.sendEntityData(communityTokenAction, cache: false),
        if (!isOwnToken)
          ionConnectNotifier.sendEntityData(
            communityTokenAction,
            actionSource: ActionSource.user(origEventReference.masterPubkey),
            metadataBuilders: [userEventsMetadataBuilder],
            cache: false,
          ),
      ]);

      return null;
    });
  }

  // TODO:pass transaction data
  Future<CommunityTokenActionData> _buildCommunityTokenAction({
    required CommunityTokenActionType type,
  }) async {
    final communityTokenDefinitionReference = await ref.read(
      communityTokenDefinitionReferenceProvider(origEventReference: origEventReference).future,
    );
    return CommunityTokenActionData.fromData(
      definitionReference: communityTokenDefinitionReference,
      network: 'foo',
      bondingCurveAddress: 'bar',
      tokenAddress: 'baz',
      transactionAddress: 'quux',
      type: type,
      amount: Random().nextDouble() * 1000,
      amountPriceUsd: Random().nextDouble() * 100,
      currency: 'ION',
    );
  }
}
