// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

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
import 'package:ion/app/features/tokenized_communities/exceptions/exceptions.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_definition_reference.f.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_provider.r.g.dart';

class CommunityTokenDefinitionRepository {
  CommunityTokenDefinitionRepository({
    required IonConnectNotifier ionConnectNotifier,
    required IonTokenAnalyticsClient analyticsClient,
    required IonConnectCache ionConnectCache,
    required Future<CommunityTokenDefinitionEntity?> Function({
      required String externalAddress,
    }) getCachedEntity,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _analyticsClient = analyticsClient,
        _ionConnectCache = ionConnectCache,
        _getCachedEntity = getCachedEntity;

  final IonConnectNotifier _ionConnectNotifier;

  final IonTokenAnalyticsClient _analyticsClient;

  final IonConnectCache _ionConnectCache;

  final Future<CommunityTokenDefinitionEntity?> Function({required String externalAddress})
      _getCachedEntity;

  Future<CommunityTokenDefinitionEntity?> getTokenDefinitionForExternalAddress(
    String externalAddress,
  ) async {
    final cachedEntity = await _getCachedEntity(externalAddress: externalAddress);

    if (cachedEntity != null) {
      return cachedEntity;
    }

    final tokenInfo = await _analyticsClient.communityTokens.getTokenInfo(externalAddress);

    if (tokenInfo == null) {
      throw TokenInfoNotFoundException(externalAddress);
    }

    final Map<String, List<Object?>> tags;

    if (tokenInfo.creator.addresses?.ionConnect == null) {
      throw TokenCreatorIonAddressNotFoundException(externalAddress);
    } else if (tokenInfo.source.isTwitter) {
      tags = {
        '#h': [tokenInfo.addresses.twitter],
      };
    } else {
      tags = {
        '#a': [externalAddress],
        '#!t': [communityTokenActionTopic],
      };
    }

    return _fetchFromIonConnect(
      creatorIonAddress: tokenInfo.creator.addresses!.ionConnect!,
      tags: tags,
    );
  }

  Future<CommunityTokenDefinitionEntity?> getTokenDefinitionForIonConnectReference(
    EventReference eventReference,
  ) async {
    final cachedEntity = await _getCachedEntity(externalAddress: eventReference.toString());

    if (cachedEntity != null) {
      return cachedEntity;
    }

    final tags = {
      '#!t': [communityTokenActionTopic],
    }..addEntries([eventReference.toFilterEntry()]);

    return _fetchFromIonConnect(
      creatorIonAddress: eventReference.masterPubkey,
      tags: tags,
    );
  }

  Future<void> cacheTokenDefinitionReference(EventMessage tokenDefinitionEvent) async {
    final tokenDefinition = CommunityTokenDefinitionEntity.fromEventMessage(tokenDefinitionEvent);
    await _ionConnectCache.cache(
      TokenDefinitionReferenceEntity.forDefinition(tokenDefinition: tokenDefinition),
    );
  }

  /// Fetches from Ion Connect with retry: first tries the user's relays, then
  /// falls back to indexer relays if the definition is not found.
  Future<CommunityTokenDefinitionEntity?> _fetchFromIonConnect({
    required String creatorIonAddress,
    Map<String, List<Object?>>? tags,
  }) async {
    var useIndexers = false;
    try {
      return await withRetry(
        ({error}) async {
          final actionSource =
              useIndexers ? const ActionSource.indexers() : ActionSource.user(creatorIonAddress);

          final result = await _queryIonConnect(
            creatorIonAddress: creatorIonAddress,
            tags: tags,
            actionSource: actionSource,
          );
          if (result != null) return result;

          useIndexers = true;
          throw const TokenDefinitionNotFoundOnRelayException();
        },
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 500),
        retryWhen: (e) => e is TokenDefinitionNotFoundOnRelayException,
      );
    } on TokenDefinitionNotFoundOnRelayException {
      return null;
    }
  }

  Future<CommunityTokenDefinitionEntity?> _queryIonConnect({
    required String creatorIonAddress,
    required ActionSource actionSource,
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
                authors: [creatorIonAddress],
                tags: tags,
                search: search,
              ),
            ),
          actionSource: actionSource,
        )
        .toList();

    final communityTokenDefinition = entities.firstWhereOrNull(
      (entity) => entity is CommunityTokenDefinitionEntity,
    );

    if (communityTokenDefinition is CommunityTokenDefinitionEntity) {
      await _ionConnectCache.cache(
        TokenDefinitionReferenceEntity.forDefinition(tokenDefinition: communityTokenDefinition),
      );
      return communityTokenDefinition;
    }

    return null;
  }
}

/// Provides cached [CommunityTokenDefinitionEntity] for given external address.
///
/// Uses cached [TokenDefinitionReferenceEntity] to find the cached definition.
@riverpod
Future<CommunityTokenDefinitionEntity?> cachedTokenDefinition(
  Ref ref, {
  required String externalAddress,
  CommunityTokenDefinitionIonType type = CommunityTokenDefinitionIonType.original,
}) async {
  final eventReference = TokenDefinitionReference.buildEventReference(
    externalAddress: externalAddress,
    type: type,
  );

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

/// Provides [CommunityTokenDefinitionEntity] for given external address.
///
/// Use this to find the definition external address, if u don't know if
/// this is an ion connect address or not - e.g. on the token details page.
/// [IMPORTANT] Works only for existing tokens.
///
/// When the result is null (e.g. relay lag), returns null immediately and
/// starts background retries via [withRetry]. When a retry succeeds the
/// provider self-invalidates so watchers pick up the resolved value.
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
  final result = await repository.getTokenDefinitionForExternalAddress(externalAddress);

  if (result != null) return result;

  _retryInBackground(ref, externalAddress, repository);
  return null;
}

/// Kicks off [withRetry] in a fire-and-forget manner. When a retry succeeds
/// the provider is invalidated so it resolves to the newly available value.
/// The retry future is cancelled when the provider is disposed.
void _retryInBackground(
  Ref ref,
  String externalAddress,
  CommunityTokenDefinitionRepository repository,
) {
  final link = ref.keepAlive();
  var cancelled = false;

  ref.onDispose(() {
    cancelled = true;
    link.close();
  });

  unawaited(
    withRetry(
      ({error}) async {
        if (cancelled) throw const BackgroundRetryCancelledException();
        final result = await repository.getTokenDefinitionForExternalAddress(externalAddress);
        if (result != null) return result;
        throw const TokenDefinitionNotFoundOnRelayException();
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 3),
      retryWhen: (e) => e is TokenDefinitionNotFoundOnRelayException && !cancelled,
    ).then((_) {
      if (!cancelled) {
        link.close();
        ref.invalidateSelf();
      }
    }).catchError((_) {
      Logger.log('[TokenDefinition] Background retries exhausted for $externalAddress');
      link.close();
    }),
  );
}

/// Provides [CommunityTokenDefinitionEntity] for given ion connect [EventReference].
///
/// Checks the cache first, then fetches from ion connect if not found.
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

/// Checks whether the ion connect entity identified by [eventReference]
/// has a token definition (might be null for old entities).
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
Future<CommunityTokenDefinitionRepository> communityTokenDefinitionRepository(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);
  Future<CommunityTokenDefinitionEntity?> getCachedEntity({
    required String externalAddress,
  }) async {
    return ref.read(cachedTokenDefinitionProvider(externalAddress: externalAddress).future);
  }

  return CommunityTokenDefinitionRepository(
    ionConnectNotifier: ionConnectNotifier,
    ionConnectCache: ionConnectCache,
    getCachedEntity: getCachedEntity,
    analyticsClient: analyticsClient,
  );
}
