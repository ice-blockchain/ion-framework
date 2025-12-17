// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_provider.r.g.dart';

class CommunityTokenDefinitionRepository {
  CommunityTokenDefinitionRepository({
    required IonConnectNotifier ionConnectNotifier,
    required IonTokenAnalyticsClient analyticsClient,
    required ExternalAddressTokenDefinitionCache externalAddressTokenDefinitionCache,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _analyticsClient = analyticsClient,
        _externalAddressTokenDefinitionCache = externalAddressTokenDefinitionCache;

  final IonConnectNotifier _ionConnectNotifier;

  final IonTokenAnalyticsClient _analyticsClient;

  final ExternalAddressTokenDefinitionCache _externalAddressTokenDefinitionCache;

  Future<CommunityTokenDefinitionEntity?> getTokenDefinitionForExternalAddress(
    String externalAddress,
  ) async {
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

    return _fetchFromIonConnect(
      externalAddress: externalAddress,
      creatorEventReference: creatorEventReference,
      tags: tags,
    );
  }

  Future<CommunityTokenDefinitionEntity?> getTokenDefinitionForIonConnectReference(
    EventReference eventReference,
  ) async {
    final externalAddress = eventReference.toString();
    final creatorEventReference = ReplaceableEventReference(
      masterPubkey: eventReference.masterPubkey,
      kind: UserMetadataEntity.kind,
    );

    final cachedEntity =
        await _externalAddressTokenDefinitionCache.get(externalAddress: eventReference.toString());

    if (cachedEntity != null) {
      return cachedEntity;
    }

    final tags = {
      '!#t': [communityTokenActionTopic],
    }..addEntries([eventReference.toFilterEntry()]);

    return _fetchFromIonConnect(
      externalAddress: externalAddress,
      creatorEventReference: creatorEventReference,
      tags: tags,
    );
  }

  Future<CommunityTokenDefinitionEntity?> _fetchFromIonConnect({
    required String externalAddress,
    required EventReference creatorEventReference,
    Map<String, List<Object?>>? tags,
  }) async {
    final search = SearchExtensions([
      RepliesCountSearchExtension(forKind: CommunityTokenDefinitionEntity.kind),
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
    required Future<CommunityTokenDefinitionEntity?> Function({
      required String externalAddress,
    }) getCachedEntity,
    required IonConnectCache ionConnectCache,
  })  : _getCachedEntity = getCachedEntity,
        _ionConnectCache = ionConnectCache;

  final Future<CommunityTokenDefinitionEntity?> Function({required String externalAddress})
      _getCachedEntity;
  final IonConnectCache _ionConnectCache;

  Future<CommunityTokenDefinitionEntity?> get({
    required String externalAddress,
  }) async {
    return _getCachedEntity(externalAddress: externalAddress);
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
Future<CommunityTokenDefinitionEntity?> cachedTokenDefinition(
  Ref ref, {
  required String externalAddress,
}) async {
  final eventReference =
      TokenDefinitionReference.buildEventReference(externalAddress: externalAddress);

  final tokenDefinitionReference = await ref
      .watch(ionConnectEntityProvider(eventReference: eventReference, network: false).future);

  if (tokenDefinitionReference is! TokenDefinitionReferenceEntity) {
    return null;
  }

  final tokenDefinition = await ref.watch(
    ionConnectEntityProvider(
      eventReference: tokenDefinitionReference.data.tokenDefinitionReference,
      network: false,
    ).future,
  );

  if (tokenDefinition is CommunityTokenDefinitionEntity) {
    return tokenDefinition;
  }

  return null;
}

@riverpod
Future<CommunityTokenDefinitionEntity?> tokenDefinitionForExternalAddress(
  Ref ref, {
  required String externalAddress,
}) async {
  final cachedTokenDefinition =
      await ref.watch(cachedTokenDefinitionProvider(externalAddress: externalAddress).future);

  if (cachedTokenDefinition != null) {
    return cachedTokenDefinition;
  }

  final repository = await ref.watch(communityTokenDefinitionRepositoryProvider.future);
  return repository.getTokenDefinitionForExternalAddress(externalAddress);
}

@riverpod
Future<CommunityTokenDefinitionEntity?> tokenDefinitionForIonConnectReference(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final cachedTokenDefinition = await ref
      .watch(cachedTokenDefinitionProvider(externalAddress: eventReference.toString()).future);

  if (cachedTokenDefinition != null) {
    return cachedTokenDefinition;
  }

  final repository = await ref.watch(communityTokenDefinitionRepositoryProvider.future);
  return repository.getTokenDefinitionForIonConnectReference(eventReference);
}

@riverpod
Future<bool> ionConnectEntityHasTokenDefinition(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final tokenDefinition = await ref
      .watch(tokenDefinitionForIonConnectReferenceProvider(eventReference: eventReference).future);
  return tokenDefinition != null;
}

@riverpod
Future<ExternalAddressTokenDefinitionCache> externalAddressTokenDefinitionCache(Ref ref) async {
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  Future<CommunityTokenDefinitionEntity?> getCachedEntity({
    required String externalAddress,
  }) async {
    return ref.read(cachedTokenDefinitionProvider(externalAddress: externalAddress).future);
  }

  return ExternalAddressTokenDefinitionCache(
    ionConnectCache: ionConnectCache,
    getCachedEntity: getCachedEntity,
  );
}

@riverpod
Future<CommunityTokenDefinitionRepository> communityTokenDefinitionRepository(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final externalAddressTokenDefinitionCache =
      await ref.watch(externalAddressTokenDefinitionCacheProvider.future);

  return CommunityTokenDefinitionRepository(
    ionConnectNotifier: ionConnectNotifier,
    analyticsClient: analyticsClient,
    externalAddressTokenDefinitionCache: externalAddressTokenDefinitionCache,
  );
}
