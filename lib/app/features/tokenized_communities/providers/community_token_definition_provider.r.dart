// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_provider.r.g.dart';

class CommunityTokenDefinitionRepository {
  CommunityTokenDefinitionRepository({
    required IonConnectNotifier ionConnectNotifier,
    required IonTokenAnalyticsClient analyticsClient,
    required ExternalAddressTokenDefinitionCache externalAddressTokenDefinitionCache,
    required String currentPubkey,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _analyticsClient = analyticsClient,
        _externalAddressTokenDefinitionCache = externalAddressTokenDefinitionCache,
        _currentPubkey = currentPubkey;

  final IonConnectNotifier _ionConnectNotifier;

  final String _currentPubkey;

  final IonTokenAnalyticsClient _analyticsClient;

  final ExternalAddressTokenDefinitionCache _externalAddressTokenDefinitionCache;

  Future<CommunityTokenDefinitionEntity?> getTokenDefinition({
    required String externalAddress,
  }) async {
    final cachedEntity =
        await _externalAddressTokenDefinitionCache.get(externalAddress: externalAddress);

    if (cachedEntity != null) {
      return cachedEntity;
    }

    final tokenInfo = await _analyticsClient.communityTokens.getTokenInfo(externalAddress);

    if (tokenInfo == null) {
      throw TokenInfoNotFoundException(externalAddress);
    }

    final creatorIonConnectAddress = tokenInfo.creator.addresses?.ionConnect;

    if (creatorIonConnectAddress == null) {
      throw TokenCreatorIonAddressNotFoundException(externalAddress);
    }

    final creatorEventReference = ReplaceableEventReference.fromString(creatorIonConnectAddress);

    final tags = switch (tokenInfo.addresses) {
      Addresses(ionConnect: final String ionConnectAddress) => {
          '#a': [ionConnectAddress],
          '!#t': [communityTokenActionTopic],
        },
      Addresses(twitter: final String twitterAddress) => {
          '#h': [twitterAddress],
        },
      _ => throw TokenAddressNotFoundException(externalAddress),
    };

    final search = SearchExtensions([
      ...SearchExtensions.withCounters(
        currentPubkey: _currentPubkey,
        forKind: CommunityTokenDefinitionEntity.kind,
      ).extensions,
      FollowingListSearchExtension(forKind: CommunityTokenDefinitionEntity.kind),
      FollowersCountSearchExtension(forKind: CommunityTokenDefinitionEntity.kind),
    ]).toString();

    final entities = await _ionConnectNotifier
        .requestEntities(
          RequestMessage()
            ..addFilter(
              RequestFilter(
                kinds: const [CommunityTokenDefinitionEntity.kind],
                authors: [creatorEventReference.masterPubkey],
                tags: tags,
                search: search,
              ),
            ),
          actionSource: ActionSource.user(creatorEventReference.masterPubkey),
        )
        .toList();

    final communityTokenDefinition = entities.firstWhereOrNull(
      (entity) => entity is CommunityTokenDefinitionEntity,
    );

    if (communityTokenDefinition is CommunityTokenDefinitionEntity) {
      await _externalAddressTokenDefinitionCache.saveReference(
        externalAddress: externalAddress,
        eventReference: communityTokenDefinition.toEventReference(),
      );
      return communityTokenDefinition;
    }

    return null;
  }
}

class ExternalAddressTokenDefinitionCache {
  ExternalAddressTokenDefinitionCache({
    required Future<IonConnectEntity?> Function({required EventReference eventReference})
        getCachedEntity,
    required IonConnectCache ionConnectCache,
  })  : _getCachedEntity = getCachedEntity,
        _ionConnectCache = ionConnectCache;

  final Future<IonConnectEntity?> Function({required EventReference eventReference})
      _getCachedEntity;

  final IonConnectCache _ionConnectCache;

  Future<CommunityTokenDefinitionEntity?> get({
    required String externalAddress,
  }) async {
    final eventReference =
        TokenDefinitionReference.buildEventReference(externalAddress: externalAddress);

    final tokenDefinitionReference = await _getCachedEntity(eventReference: eventReference);

    if (tokenDefinitionReference is! TokenDefinitionReferenceEntity) {
      return null;
    }

    final tokenDefinition = await _getCachedEntity(
      eventReference: tokenDefinitionReference.data.tokenDefinitionReference,
    );

    if (tokenDefinition is CommunityTokenDefinitionEntity) {
      return tokenDefinition;
    }

    return null;
  }

  Future<void> saveReference({
    required String externalAddress,
    required ReplaceableEventReference eventReference,
  }) async {
    final tokenDefinitionReference = TokenDefinitionReferenceEntity.fromData(
      tokenDefinitionReference: eventReference,
      externalAddress: externalAddress,
    );
    await _ionConnectCache.cache(tokenDefinitionReference);
  }
}

@riverpod
Future<CommunityTokenDefinitionEntity?> communityTokenDefinition(
  Ref ref, {
  required String externalAddress,
}) async {
  final repository = await ref.watch(communityTokenDefinitionRepositoryProvider.future);
  return repository.getTokenDefinition(externalAddress: externalAddress);
}

@riverpod
Future<ExternalAddressTokenDefinitionCache> externalAddressTokenDefinitionCache(Ref ref) async {
  Future<IonConnectEntity?> getCachedEntity({required EventReference eventReference}) =>
      ref.read(ionConnectEntityProvider(eventReference: eventReference, network: false).future);

  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);

  return ExternalAddressTokenDefinitionCache(
    getCachedEntity: getCachedEntity,
    ionConnectCache: ionConnectCache,
  );
}

@riverpod
Future<CommunityTokenDefinitionRepository> communityTokenDefinitionRepository(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final externalAddressTokenDefinitionCache =
      await ref.watch(externalAddressTokenDefinitionCacheProvider.future);
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  return CommunityTokenDefinitionRepository(
    ionConnectNotifier: ionConnectNotifier,
    analyticsClient: analyticsClient,
    externalAddressTokenDefinitionCache: externalAddressTokenDefinitionCache,
    currentPubkey: currentPubkey,
  );
}
