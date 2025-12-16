// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_ion_connect_notifier_provider.r.g.dart';

class CommunityTokenIonConnectService {
  CommunityTokenIonConnectService({
    required IonConnectNotifier ionConnectNotifier,
    required CommunityTokenDefinitionRepository communityTokenDefinitionRepository,
    required UserEventsMetadataBuilder userEventsMetadataBuilder,
    required bool Function(String masterPubkey) isCurrentUserSelector,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _communityTokenDefinitionRepository = communityTokenDefinitionRepository,
        _userEventsMetadataBuilder = userEventsMetadataBuilder,
        _isCurrentUserSelector = isCurrentUserSelector;

  final IonConnectNotifier _ionConnectNotifier;

  final CommunityTokenDefinitionRepository _communityTokenDefinitionRepository;

  final UserEventsMetadataBuilder _userEventsMetadataBuilder;

  final bool Function(String masterPubkey) _isCurrentUserSelector;

  Future<void> sendBuyEvents({
    required String externalAddress,
    required bool firstBuy,
  }) async {
    final communityTokenDefinition =
        await _fetchCommunityTokenDefinition(externalAddress: externalAddress);

    final communityTokenAction = await _buildCommunityTokenAction(
      communityTokenDefinition: communityTokenDefinition,
      type: CommunityTokenActionType.buy,
    );

    final communityTokenDefinitionData = communityTokenDefinition.data;

    if (communityTokenDefinitionData is CommunityTokenDefinitionExternal) {
      return _sendExternalBuyEvents(
        communityTokenDefinition: communityTokenDefinition,
        communityTokenAction: communityTokenAction,
      );
    } else if (communityTokenDefinitionData is CommunityTokenDefinitionIon) {
      return _sendIonBuyEvents(
        communityTokenDefinition: communityTokenDefinition,
        communityTokenAction: communityTokenAction,
        firstBuy: firstBuy,
      );
    } else {
      throw StateError(
        'Unsupported CommunityTokenDefinitionData type: ${communityTokenDefinition.data.runtimeType}',
      );
    }
  }

  Future<void> sendSellEvents({
    required String externalAddress,
  }) async {
    final communityTokenDefinition =
        await _fetchCommunityTokenDefinition(externalAddress: externalAddress);

    final communityTokenAction = await _buildCommunityTokenAction(
      communityTokenDefinition: communityTokenDefinition,
      type: CommunityTokenActionType.sell,
    );

    return _sendSellEvents(
      communityTokenDefinition: communityTokenDefinition,
      communityTokenAction: communityTokenAction,
    );
  }

  /// For external tokens (X), we don't create "first buy" definition events
  /// and it can't be the user's own token, because external token definitions
  /// are created by internal backend users.
  Future<void> _sendExternalBuyEvents({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionData communityTokenAction,
  }) async {
    final tokenActionEvent = await _ionConnectNotifier.sign(communityTokenAction);
    await Future.wait([
      _ionConnectNotifier.sendEvent(tokenActionEvent),
      _ionConnectNotifier.sendEvent(
        tokenActionEvent,
        actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
        metadataBuilders: [_userEventsMetadataBuilder],
        cache: false,
      ),
    ]);
  }

  /// For Ion tokens, if this is a first token buy action,
  /// "first-buy" definition event must be sent to the profile / content
  /// owner’s relays.
  Future<void> _sendIonBuyEvents({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionData communityTokenAction,
    required bool firstBuy,
  }) async {
    final communityTokenDefinitionData = communityTokenDefinition.data;

    if (communityTokenDefinitionData is! CommunityTokenDefinitionIon) {
      throw StateError(
        'communityTokenDefinitionData must be of type CommunityTokenDefinitionIon',
      );
    }

    final isOwnToken = _isCurrentUserSelector(communityTokenDefinition.masterPubkey);
    final tokenDefinitionFirstBuy = await _buildCommunityTokenDefinitionFirstBuy(
      communityTokenDefinition: communityTokenDefinitionData,
    );
    final (tokenActionEvent, tokenDefinitionFirstBuyEvent) = await (
      _ionConnectNotifier.sign(communityTokenAction),
      _ionConnectNotifier.sign(tokenDefinitionFirstBuy)
    ).wait;

    await Future.wait([
      _ionConnectNotifier.sendEvents(
        [
          tokenActionEvent,
          if (firstBuy && isOwnToken) tokenDefinitionFirstBuyEvent,
        ],
      ),
      if (!isOwnToken)
        _ionConnectNotifier.sendEvents(
          [
            tokenActionEvent,
            if (firstBuy) tokenDefinitionFirstBuyEvent,
          ],
          actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
          metadataBuilders: [_userEventsMetadataBuilder],
          cache: false,
        ),
    ]);
  }

  /// For sell actions, we create only community token action events.
  Future<void> _sendSellEvents({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionData communityTokenAction,
  }) async {
    final isOwnToken = _isCurrentUserSelector(communityTokenDefinition.masterPubkey);
    final tokenActionEvent = await _ionConnectNotifier.sign(communityTokenAction);
    await Future.wait([
      _ionConnectNotifier.sendEvent(tokenActionEvent, cache: false),
      if (!isOwnToken)
        _ionConnectNotifier.sendEvent(
          tokenActionEvent,
          actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
          metadataBuilders: [_userEventsMetadataBuilder],
          cache: false,
        ),
    ]);
  }

  Future<CommunityTokenDefinitionEntity> _fetchCommunityTokenDefinition({
    required String externalAddress,
  }) async {
    final communityTokenDefinition = await _communityTokenDefinitionRepository.getTokenDefinition(
      externalAddress: externalAddress,
    );

    if (communityTokenDefinition == null) {
      throw TokenDefinitionNotFoundException(externalAddress);
    }

    return communityTokenDefinition;
  }

  //TODO: pass all required data
  Future<CommunityTokenActionData> _buildCommunityTokenAction({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionType type,
  }) async {
    return CommunityTokenActionData.fromData(
      definitionReference: communityTokenDefinition.toEventReference(),
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

  Future<CommunityTokenDefinitionIon> _buildCommunityTokenDefinitionFirstBuy({
    required CommunityTokenDefinitionIon communityTokenDefinition,
  }) async {
    return CommunityTokenDefinitionIon.fromEventReference(
      eventReference: communityTokenDefinition.eventReference,
      kind: communityTokenDefinition.kind,
      type: CommunityTokenDefinitionIonType.firstBuyAction,
    );
  }
}

@riverpod
Future<CommunityTokenIonConnectService> communityTokenIonConnectService(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final communityTokenDefinitionRepository =
      await ref.watch(communityTokenDefinitionRepositoryProvider.future);
  final userEventsMetadataBuilder = await ref.watch(userEventsMetadataBuilderProvider.future);
  bool isCurrentUserSelector(String masterPubkey) {
    return ref.read(isCurrentUserSelectorProvider(masterPubkey));
  }

  return CommunityTokenIonConnectService(
    ionConnectNotifier: ionConnectNotifier,
    communityTokenDefinitionRepository: communityTokenDefinitionRepository,
    userEventsMetadataBuilder: userEventsMetadataBuilder,
    isCurrentUserSelector: isCurrentUserSelector,
  );
}
