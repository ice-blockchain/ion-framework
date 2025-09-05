// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_db_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/relays_reachability_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_relays_manager.r.g.dart';

/// Finds reachable relays for the given user pubkeys.
///
/// Use this method when you need to find relays for a specific user or users.
/// Returns a list of reachable user relays for each provided pubkey.
///
/// Current user:
/// Relay list is taken directly from the identity, because, for example,
///   during onboarding, the user does not have relays yet in the database / indexers.
///
/// Other users:
/// If a relay list is already cached in the database,
///   it is returned from there.
/// If a relay list is not found in the database,
///   it is fetched from indexers and cached.
/// If a relay list is still not found,
///   it is fetched from the identity and cached.
@riverpod
class UserRelaysManager extends _$UserRelaysManager {
  @override
  FutureOr<void> build() async {}

  Future<List<UserRelaysEntity>> fetchReachableRelays(List<String> pubkeys) async {
    final currentUserReachableRelays = await _getCurrentUserReachableRelaysIfRequested(pubkeys);

    final result = <UserRelaysEntity>[
      if (currentUserReachableRelays != null) currentUserReachableRelays,
    ];

    final pubkeysToFetch =
        pubkeys.where((pubkey) => pubkey != currentUserReachableRelays?.masterPubkey).toList();

    if (pubkeysToFetch.isEmpty) {
      return result;
    }

    final dbCachedRelays = await _getRelaysFromDb(pubkeys: pubkeysToFetch);
    final reachableDbCachedRelays = _filterReachableRelays(dbCachedRelays);
    result.addAll(reachableDbCachedRelays);

    pubkeysToFetch.removeWhere(
      (pubkey) => reachableDbCachedRelays.any((relay) => relay.masterPubkey == pubkey),
    );

    if (pubkeysToFetch.isEmpty) {
      return result;
    }

    final fetchedRelays = <UserRelaysEntity>[];

    final relaysFromIndexers = await fetchRelaysFromIndexers(pubkeysToFetch);
    final reachableRelaysFromIndexers = _filterReachableRelays(relaysFromIndexers);

    fetchedRelays.addAll(reachableRelaysFromIndexers);
    result.addAll(reachableRelaysFromIndexers);

    pubkeysToFetch.removeWhere(
      (pubkey) => reachableRelaysFromIndexers.any((relay) => relay.masterPubkey == pubkey),
    );

    if (pubkeysToFetch.isEmpty) {
      return result;
    }

    final relaysFromIdentity = await fetchRelaysFromIdentity(pubkeysToFetch);

    fetchedRelays.addAll(relaysFromIdentity);
    result.addAll(relaysFromIdentity);

    await _clearReachabilityInfoFor(fetchedRelays);

    return result;
  }

  /// Marks a relay as read-only in the local cache.
  ///
  /// If after the update no write relays remain in the list,
  /// the entire entity is removed from the cache.
  /// That in turn leads to refetching from the remote source
  /// on the next request for the user relays.
  Future<void> handleCachedReadOnlyRelay(String relayUrl) async {
    final cachedRelayEntities = (await ref
            .read(ionConnectDatabaseCacheProvider.notifier)
            .getAllFiltered(keyword: relayUrl, kinds: [UserRelaysEntity.kind]))
        .cast<UserRelaysEntity>();

    final updatedEntities = <UserRelaysEntity>[];
    final outdatedEntities = <UserRelaysEntity>[];
    for (final entity in cachedRelayEntities) {
      if (entity.data.list.any((relay) => relay.url == relayUrl && !relay.write)) {
        continue; // Skip if the relay is already marked as read-only
      }

      final updatedData = entity.data.copyWith(
        list: entity.data.list
            .map((relay) => relay.url == relayUrl ? relay.copyWith(write: false) : relay)
            .toList(),
      );

      if (updatedData.list.any((relay) => relay.write)) {
        updatedEntities.add(entity.copyWith(data: updatedData));
      } else {
        outdatedEntities.add(entity);
      }
    }

    await Future.wait([
      ref
          .read(ionConnectDatabaseCacheProvider.notifier)
          .removeAll(outdatedEntities.map((entity) => entity.toEventReference()).toList()),
      ref.read(ionConnectDatabaseCacheProvider.notifier).saveAll(updatedEntities),
    ]);
  }

  Future<List<UserRelaysEntity>> fetchRelaysFromIndexers(List<String> pubkeys) async {
    final result = <UserRelaysEntity>[];
    final indexers = await ref.read(currentUserIndexersProvider.future);
    if (indexers != null && indexers.isNotEmpty) {
      final requestMessage = RequestMessage()
        ..addFilter(
          RequestFilter(kinds: const [UserRelaysEntity.kind], authors: pubkeys),
        );

      final entitiesStream = ref
          .read(ionConnectNotifierProvider.notifier)
          .requestEntities(requestMessage, actionSource: const ActionSourceIndexers());

      await for (final entity in entitiesStream) {
        if (entity is UserRelaysEntity) {
          result.add(entity);
        }
      }
    }
    return result;
  }

  Future<List<UserRelaysEntity>> fetchRelaysFromIdentity(List<String> pubkeys) async {
    final ionIdentity = await ref.read(ionIdentityClientProvider.future);
    final usersIdentityRelays = await ionIdentity.users.ionConnectRelays(masterPubkeys: pubkeys);

    final userRelays = [
      for (final relay in usersIdentityRelays)
        if (relay.ionConnectRelays.isNotEmpty)
          UserRelaysEntity(
            id: '',
            signature: '',
            masterPubkey: relay.masterPubKey,
            pubkey: relay.masterPubKey,
            createdAt: DateTime.now().microsecondsSinceEpoch,
            data: UserRelaysData(
              list: relay.ionConnectRelays.map((relay) => relay.toUserRelay()).toList(),
            ),
          ),
    ]..forEach(ref.read(ionConnectCacheProvider.notifier).cache);

    return userRelays;
  }

  Future<UserRelaysEntity?> _getCurrentUserReachableRelaysIfRequested(List<String> pubkeys) async {
    final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserPubkey != null && pubkeys.contains(currentUserPubkey)) {
      final currentUserRelays = await ref.read(currentUserRelaysProvider.future);
      if (currentUserRelays != null) {
        return _filterReachableRelays([currentUserRelays]).firstOrNull;
      }
    }

    return null;
  }

  Future<List<UserRelaysEntity>> _getRelaysFromDb({
    required List<String> pubkeys,
  }) async {
    final eventReferences = pubkeys
        .map(
          (pubkey) => ReplaceableEventReference(
            masterPubkey: pubkey,
            kind: UserRelaysEntity.kind,
          ),
        )
        .toList();

    return (await ref.read(ionConnectDatabaseCacheProvider.notifier).getAll(eventReferences))
        .cast<UserRelaysEntity?>()
        .nonNulls
        .toList();
  }

  List<UserRelaysEntity> _filterReachableRelays(List<UserRelaysEntity> relays) {
    return relays
        .map(ref.read(relayReachabilityProvider.notifier).getFilteredRelayEntity)
        .nonNulls
        .toList();
  }

  Future<void> _clearReachabilityInfoFor(
    List<UserRelaysEntity> relays,
  ) async {
    final reachabilityInfoNotifier = ref.read(relayReachabilityProvider.notifier);
    final relayUrls = relays.map((relay) => relay.urls).expand((element) => element).toSet();
    for (final url in relayUrls) {
      await reachabilityInfoNotifier.clear(url);
    }
  }

  static bool isRelayReadOnlyError(Object? error) {
    return error is SendEventException && error.code.startsWith('relay-is-read-only');
  }

  static bool relayListsEqual(List<UserRelay>? list1, List<UserRelay>? list2) {
    return const UnorderedIterableEquality<UserRelay>().equals(list1, list2);
  }
}

@riverpod
Future<UserRelaysEntity?> currentUserRelays(Ref ref) async {
  final identityConnectRelays = await ref.watch(currentUserIdentityConnectRelaysProvider.future);
  if (identityConnectRelays == null) {
    return null;
  }
  final updatedUserRelays = UserRelaysData(list: identityConnectRelays);
  final userRelaysEvent =
      await ref.read(ionConnectNotifierProvider.notifier).sign(updatedUserRelays);

  return UserRelaysEntity.fromEventMessage(userRelaysEvent);
}
