// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_auth_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_action_first_buy_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/transaction_amount.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_ion_connect_notifier_provider.r.g.dart';

class CommunityTokenIonConnectService {
  CommunityTokenIonConnectService({
    required IonConnectNotifier ionConnectNotifier,
    required IonConnectCache ionConnectCache,
    required CommunityTokenDefinitionRepository communityTokenDefinitionRepository,
    required UserEventsMetadataBuilder userEventsMetadataBuilder,
    required bool Function(String masterPubkey) isCurrentUserSelector,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _ionConnectCache = ionConnectCache,
        _communityTokenDefinitionRepository = communityTokenDefinitionRepository,
        _userEventsMetadataBuilder = userEventsMetadataBuilder,
        _isCurrentUserSelector = isCurrentUserSelector;

  final IonConnectNotifier _ionConnectNotifier;

  final IonConnectCache _ionConnectCache;

  final CommunityTokenDefinitionRepository _communityTokenDefinitionRepository;

  final UserEventsMetadataBuilder _userEventsMetadataBuilder;

  final bool Function(String masterPubkey) _isCurrentUserSelector;

  Future<void> sendBuyEvents({
    required String externalAddress,
    required bool firstBuy,
    required String network,
    required String bondingCurveAddress,
    required String tokenAddress,
    required String transactionAddress,
    required TransactionAmount amountBase,
    required TransactionAmount amountQuote,
    required TransactionAmount amountUsd,
  }) async {
    final communityTokenDefinition =
        await _fetchCommunityTokenDefinition(externalAddress: externalAddress);

    final communityTokenAction = await _buildCommunityTokenAction(
      communityTokenDefinition: communityTokenDefinition,
      type: CommunityTokenActionType.buy,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      amountBase: amountBase,
      amountQuote: amountQuote,
      amountUsd: amountUsd,
    );

    final communityTokenDefinitionData = communityTokenDefinition.data;

    if (communityTokenDefinitionData is CommunityTokenDefinitionExternal) {
      await _sendExternalBuyEvents(
        communityTokenDefinition: communityTokenDefinition,
        communityTokenAction: communityTokenAction,
      );
    } else if (communityTokenDefinitionData is CommunityTokenDefinitionIon) {
      await _sendIonBuyEvents(
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
    required String network,
    required String bondingCurveAddress,
    required String tokenAddress,
    required String transactionAddress,
    required TransactionAmount amountBase,
    required TransactionAmount amountQuote,
    required TransactionAmount amountUsd,
  }) async {
    final communityTokenDefinition =
        await _fetchCommunityTokenDefinition(externalAddress: externalAddress);

    final communityTokenAction = await _buildCommunityTokenAction(
      communityTokenDefinition: communityTokenDefinition,
      type: CommunityTokenActionType.sell,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      amountBase: amountBase,
      amountQuote: amountQuote,
      amountUsd: amountUsd,
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

    if (firstBuy) {
      // Since we send [tokenDefinitionFirstBuyEvent] only to the token owner's relays,
      // we must ensure the event is accepted by the relay.
      // If a RelayAuthoritativeError occurs (i.e., the token owner shares the same relays
      // as the current user and the event is rejected), we need to retry sending the event
      // to our own relays.
      await Future.wait([
        _ionConnectNotifier.sendEvents(
          [
            tokenActionEvent,
            if (isOwnToken) tokenDefinitionFirstBuyEvent,
          ],
        ),
        if (!isOwnToken)
          _ionConnectNotifier
              .sendEvents(
                [
                  tokenActionEvent,
                  tokenDefinitionFirstBuyEvent,
                ],
                actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
                metadataBuilders: [_userEventsMetadataBuilder],
                ignoreAuthoritativeErrors: false,
              )
              .catchError(
                (_) => _ionConnectNotifier.sendEvents([tokenDefinitionFirstBuyEvent]),
                test: RelayAuthService.isRelayAuthoritativeError,
              ),
      ]);

      await _cacheTokenActionFirstBuyReference(
        communityTokenDefinition: communityTokenDefinition,
        communityTokenActionEvent: tokenActionEvent,
      );
    } else {
      await Future.wait([
        _ionConnectNotifier.sendEvent(tokenActionEvent),
        if (!isOwnToken)
          _ionConnectNotifier.sendEvent(
            tokenActionEvent,
            actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
            metadataBuilders: [_userEventsMetadataBuilder],
          ),
      ]);
    }
  }

  /// For sell actions, we create only community token action events.
  Future<void> _sendSellEvents({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionData communityTokenAction,
  }) async {
    final isOwnToken = _isCurrentUserSelector(communityTokenDefinition.masterPubkey);
    final tokenActionEvent = await _ionConnectNotifier.sign(communityTokenAction);
    await Future.wait([
      _ionConnectNotifier.sendEvent(tokenActionEvent),
      if (!isOwnToken)
        _ionConnectNotifier.sendEvent(
          tokenActionEvent,
          actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
          metadataBuilders: [_userEventsMetadataBuilder],
        ),
    ]);
  }

  Future<CommunityTokenDefinitionEntity> _fetchCommunityTokenDefinition({
    required String externalAddress,
  }) async {
    final communityTokenDefinition = await _communityTokenDefinitionRepository
        .getTokenDefinitionForExternalAddress(externalAddress);

    if (communityTokenDefinition == null) {
      throw TokenDefinitionNotFoundException(externalAddress);
    }

    return communityTokenDefinition;
  }

  Future<CommunityTokenActionData> _buildCommunityTokenAction({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required CommunityTokenActionType type,
    required String network,
    required String bondingCurveAddress,
    required String tokenAddress,
    required String transactionAddress,
    required TransactionAmount amountBase,
    required TransactionAmount amountQuote,
    required TransactionAmount amountUsd,
  }) async {
    if (amountUsd.currency != TransactionAmount.usdCurrency) {
      throw ArgumentError.value(
        amountUsd,
        'amountUsd',
        'The currency of amountUsd must be ${TransactionAmount.usdCurrency}',
      );
    }

    return CommunityTokenActionData.fromData(
      definitionReference: communityTokenDefinition.toEventReference(),
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      type: type,
      amountBase: amountBase,
      amountQuote: amountQuote,
      amountUsd: amountUsd,
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

  /// Caches TokenActionFirstBuyReferenceEntity to indicate that an event has
  /// a token created (it is created on the first buy from any user).
  Future<void> _cacheTokenActionFirstBuyReference({
    required CommunityTokenDefinitionEntity communityTokenDefinition,
    required EventMessage communityTokenActionEvent,
  }) async {
    final communityTokenAction =
        CommunityTokenActionEntity.fromEventMessage(communityTokenActionEvent);
    final firstBuyReferenceEntity =
        TokenActionFirstBuyReferenceEntity.fromCommunityTokenAction(communityTokenAction).copyWith(
      masterPubkey: TokenActionFirstBuyReference.anyUserMasterPubkey,
    );

    await _ionConnectCache.cache(firstBuyReferenceEntity);
  }
}

@riverpod
Future<CommunityTokenIonConnectService> communityTokenIonConnectService(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  final communityTokenDefinitionRepository =
      await ref.watch(communityTokenDefinitionRepositoryProvider.future);
  final userEventsMetadataBuilder = await ref.watch(userEventsMetadataBuilderProvider.future);
  bool isCurrentUserSelector(String masterPubkey) {
    return ref.read(isCurrentUserSelectorProvider(masterPubkey));
  }

  return CommunityTokenIonConnectService(
    ionConnectNotifier: ionConnectNotifier,
    ionConnectCache: ionConnectCache,
    communityTokenDefinitionRepository: communityTokenDefinitionRepository,
    userEventsMetadataBuilder: userEventsMetadataBuilder,
    isCurrentUserSelector: isCurrentUserSelector,
  );
}
