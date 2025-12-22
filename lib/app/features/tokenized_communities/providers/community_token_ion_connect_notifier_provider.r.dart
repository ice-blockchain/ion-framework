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
import 'package:ion/app/features/tokenized_communities/models/entities/token_definition_reference.f.dart';
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

  Future<void> sendFirstBuyEvents({
    required String externalAddress,
  }) async {
    final communityTokenDefinition =
        await _fetchCommunityTokenDefinition(externalAddress: externalAddress);
    final communityTokenDefinitionData = communityTokenDefinition.data;

    if (communityTokenDefinitionData is! CommunityTokenDefinitionIon) {
      // For external tokens (X), we don't create "first buy" definition events
      throw StateError('communityTokenDefinitionData must be of type CommunityTokenDefinitionIon');
    }

    final tokenDefinitionFirstBuy = await _buildCommunityTokenDefinitionFirstBuy(
      communityTokenDefinition: communityTokenDefinitionData,
    );
    final tokenDefinitionFirstBuyEvent = await _ionConnectNotifier.sign(tokenDefinitionFirstBuy);
    final isOwnToken = _isCurrentUserSelector(communityTokenDefinition.masterPubkey);

    if (isOwnToken) {
      await _ionConnectNotifier.sendEvent(tokenDefinitionFirstBuyEvent);
      return;
    }

    await _ionConnectNotifier
        .sendEvent(
          tokenDefinitionFirstBuyEvent,
          actionSource: ActionSource.user(communityTokenDefinition.masterPubkey),
          metadataBuilders: [_userEventsMetadataBuilder],
          // Since we're sending this event only to the token owner, if owner shares
          // relays with the current user, we need to retry the sending to the current
          // user's relays in case of is-relay-authoritative error.
          ignoreAuthoritativeErrors: false,
        )
        .catchError(
          (_) => _ionConnectNotifier.sendEvent(tokenDefinitionFirstBuyEvent),
          test: RelayAuthService.isRelayAuthoritativeError,
        );

    await _cacheTokenDefinitionFirstBuyReference(
      tokenDefinitionFirstBuyEvent: tokenDefinitionFirstBuyEvent,
    );
  }

  Future<void> sendBuyActionEvents({
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
      type: CommunityTokenActionType.buy,
      network: network,
      bondingCurveAddress: bondingCurveAddress,
      tokenAddress: tokenAddress,
      transactionAddress: transactionAddress,
      amountBase: amountBase,
      amountQuote: amountQuote,
      amountUsd: amountUsd,
    );

    await _sendActionEvents(
      communityTokenDefinition: communityTokenDefinition,
      communityTokenAction: communityTokenAction,
    );
  }

  Future<void> sendSellActionEvents({
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

    return _sendActionEvents(
      communityTokenDefinition: communityTokenDefinition,
      communityTokenAction: communityTokenAction,
    );
  }

  Future<void> _sendActionEvents({
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

  /// Caches TokenDefinitionReferenceEntity to indicate that an event has
  /// a token (it is created on the first buy from any user).
  Future<void> _cacheTokenDefinitionFirstBuyReference({
    required EventMessage tokenDefinitionFirstBuyEvent,
  }) async {
    final tokenDefinitionFirstBuy =
        CommunityTokenDefinitionEntity.fromEventMessage(tokenDefinitionFirstBuyEvent);
    final firstBuyReferenceEntity =
        TokenDefinitionReferenceEntity.forDefinition(tokenDefinition: tokenDefinitionFirstBuy);
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
