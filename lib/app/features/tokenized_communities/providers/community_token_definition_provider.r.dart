// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_provider.r.g.dart';

class CommunityTokenDefinitionRepository {
  CommunityTokenDefinitionRepository({
    required IonConnectNotifier ionConnectNotifier,
    required IonTokenAnalyticsClient analyticsClient,
    required CommunityTokenReferenceCache cache,
    required String currentPubkey,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _analyticsClient = analyticsClient,
        _cache = cache,
        _currentPubkey = currentPubkey;

  final IonConnectNotifier _ionConnectNotifier;

  final String _currentPubkey;

  final IonTokenAnalyticsClient _analyticsClient;

  final CommunityTokenReferenceCache _cache;

  Future<CommunityTokenDefinitionEntity?> getTokenDefinition({
    required String externalAddress,
  }) async {
    final cachedEntity = await _cache.get(externalAddress: externalAddress);

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

    final entity = await _ionConnectNotifier.requestEntity<CommunityTokenDefinitionEntity>(
      RequestMessage()
        ..addFilter(
          const RequestFilter(
            kinds: [CommunityTokenDefinitionEntity.kind],
            // kreios
            authors: ['9f5601d4f81ce1209c4ca49e3ca943ad9ccdd8085200458ff8b2e127655d870d'],
          ),
        ),
      //kreios
      actionSource: const ActionSource.user(
        '9f5601d4f81ce1209c4ca49e3ca943ad9ccdd8085200458ff8b2e127655d870d',
      ),
    );

    if (entity != null) {
      await _cache.saveReference(
        externalAddress: externalAddress,
        eventReference: entity.toEventReference(),
      );
    }

    return entity;
  }
}

class CommunityTokenReferenceCache {
  CommunityTokenReferenceCache({
    required LocalStorage localStorage,
    required Future<IonConnectEntity?> Function({required EventReference eventReference})
        getCachedEntity,
  })  : _localStorage = localStorage,
        _getCachedEntity = getCachedEntity;

  final LocalStorage _localStorage;

  final Future<IonConnectEntity?> Function({required EventReference eventReference})
      _getCachedEntity;

  static const _keyPrefix = 'community_token_definition_';

  String _getCacheKey(String externalAddress) => '$_keyPrefix$externalAddress';

  Future<CommunityTokenDefinitionEntity?> get({
    required String externalAddress,
  }) async {
    final savedReference = await _getSavedReference(externalAddress: externalAddress);

    if (savedReference == null) {
      return null;
    }

    final cachedEntity = await _getCachedEntity(eventReference: savedReference);

    if (cachedEntity is CommunityTokenDefinitionEntity) {
      return cachedEntity;
    }

    return null;
  }

  Future<EventReference?> _getSavedReference({required String externalAddress}) async {
    final key = _getCacheKey(externalAddress);
    final value = _localStorage.getString(key);

    if (value == null) {
      return null;
    }

    try {
      final tagList = List<String>.from(jsonDecode(value) as List<dynamic>);
      return EventReference.fromTag(tagList);
    } catch (e) {
      await _localStorage.remove(key);
      return null;
    }
  }

  Future<void> saveReference({
    required String externalAddress,
    required EventReference eventReference,
  }) async {
    final key = _getCacheKey(externalAddress);
    final tagList = eventReference.toTag();
    final value = jsonEncode(tagList);
    await _localStorage.setString(key, value);
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
Future<CommunityTokenReferenceCache> communityTokenDefinitionCache(Ref ref) async {
  final localStorage = ref.watch(localStorageProvider);
  Future<IonConnectEntity?> getCachedEntity({required EventReference eventReference}) =>
      ref.read(ionConnectEntityProvider(eventReference: eventReference, network: false).future);

  return CommunityTokenReferenceCache(
    localStorage: localStorage,
    getCachedEntity: getCachedEntity,
  );
}

@riverpod
Future<CommunityTokenDefinitionRepository> communityTokenDefinitionRepository(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final cache = await ref.watch(communityTokenDefinitionCacheProvider.future);
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  return CommunityTokenDefinitionRepository(
    ionConnectNotifier: ionConnectNotifier,
    analyticsClient: analyticsClient,
    cache: cache,
    currentPubkey: currentPubkey,
  );
}
