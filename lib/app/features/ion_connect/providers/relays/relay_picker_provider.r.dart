// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart' hide requestEvents;
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/disliked_relay_urls_collection.f.dart';
import 'package:ion/app/features/ion_connect/providers/relays/active_relays_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_provider.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/ranked_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/relevant_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_picker_provider.r.g.dart';

enum ActionType { read, write }

@riverpod
class RelayPicker extends _$RelayPicker {
  @override
  FutureOr<void> build() {}

  Future<Map<IonConnectRelay, Set<String>>> getActionSourceRelays(
    ActionSource actionSource, {
    required ActionType actionType,
    DislikedRelayUrlsCollection dislikedUrls = const DislikedRelayUrlsCollection({}),
    String? sessionId,
  }) async {
    return switch (actionType) {
      ActionType.read => _getReadActionSourceRelays(actionSource, dislikedUrls: dislikedUrls),
      ActionType.write => _getWriteActionSourceRelay(actionSource, dislikedUrls: dislikedUrls),
    };
  }

  Future<Map<IonConnectRelay, Set<String>>> _getWriteActionSourceRelay(
    ActionSource actionSource, {
    DislikedRelayUrlsCollection dislikedUrls = const DislikedRelayUrlsCollection({}),
    String? sessionId,
  }) async {
    final reachableRelays = switch (actionSource) {
      ActionSourceCurrentUser() => await _getCurrentUserReachableRelays().then(_filterWriteRelays),
      ActionSourceUser() =>
        await _getUserReachableRelays(actionSource.pubkey).then(_filterWriteRelays),
      ActionSourceRelayUrl() => [UserRelay(url: actionSource.url)],
      _ => throw UnsupportedError(
          'ActionSource $actionSource is not supported for write action type.',
        )
    };

    final sessionPrefix = sessionId != null ? '[SESSION] Session $sessionId - ' : '';
    Logger.log(
      '$sessionPrefix[RELAY] Selecting a write relay for action source: $actionSource, reachable write relay list: $reachableRelays, disliked: ${dislikedUrls.urls}',
    );

    final reachableRelayUrls = reachableRelays.map((relay) => relay.url).toList();
    final filteredWriteRelayUrls = _filterOutDislikedRelayUrls(reachableRelayUrls, dislikedUrls);

    if (filteredWriteRelayUrls.isEmpty) {
      Logger.warning(
        '$sessionPrefix[RELAY] No available write relays found for action source: $actionSource. Fallback to read action source relay.',
      );

      return _getReadActionSourceRelays(actionSource, dislikedUrls: dislikedUrls);
    }

    final chosenRelayUrl =
        _getFirstActiveRelayUrl(filteredWriteRelayUrls) ?? filteredWriteRelayUrls.random!;
    Logger.log(
      '$sessionPrefix[RELAY] Write relay selected: $chosenRelayUrl from pool: $filteredWriteRelayUrls, disliked: ${dislikedUrls.urls}',
    );
    final chosenRelay =
        await ref.read(relayProvider(chosenRelayUrl, anonymous: actionSource.anonymous).future);
    return {chosenRelay: {}};
  }

  Future<Map<IonConnectRelay, Set<String>>> _getReadActionSourceRelays(
    ActionSource actionSource, {
    DislikedRelayUrlsCollection dislikedUrls = const DislikedRelayUrlsCollection({}),
    String? sessionId,
  }) async {
    final sessionPrefix = sessionId != null ? '[SESSION] Session $sessionId - ' : '';
    Logger.log(
      '$sessionPrefix[RELAY] Selecting a read relay for action source: $actionSource, $dislikedUrls',
    );

    switch (actionSource) {
      case ActionSourceCurrentUser():
        final currentUserRankedRelays = await _getCurrentUserRankedRelays();
        final currentUserRankedRelayUrls =
            currentUserRankedRelays.map((relay) => relay.url).toList();
        final filteredRankedRelays =
            _filterOutDislikedRelayUrls(currentUserRankedRelayUrls, dislikedUrls);

        // If we already tried all current user ranked relays and they were disliked,
        // we continue retrying with the best relay from the full list.
        final relayPool =
            filteredRankedRelays.isNotEmpty ? filteredRankedRelays : currentUserRankedRelayUrls;

        if (relayPool.isEmpty) {
          throw FailedToPickUserRelay('Current user relay pool is empty.');
        }

        final chosenRelayUrl = _getFirstActiveRelayUrl(relayPool) ?? relayPool.first;
        Logger.log(
          '$sessionPrefix[RELAY] Current user read relay selected: $chosenRelayUrl from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
        final chosenRelay =
            await ref.read(relayProvider(chosenRelayUrl, anonymous: actionSource.anonymous).future);
        return {
          chosenRelay: {chosenRelayUrl},
        };

      case ActionSourceUser():
        if (ref.read(isCurrentUserSelectorProvider(actionSource.pubkey))) {
          return _getReadActionSourceRelays(
            ActionSource.currentUser(anonymous: actionSource.anonymous),
            dislikedUrls: dislikedUrls,
            sessionId: sessionId,
          );
        }

        final reachableRelays = await _getUserReachableRelays(actionSource.pubkey)
            .then((userRelays) => userRelays.data.list);
        final reachableRelayUrls = reachableRelays.map((relay) => relay.url).toList();
        final filteredReachableRelays =
            _filterOutDislikedRelayUrls(reachableRelayUrls, dislikedUrls);

        // If we already tried all reachable user relays and they were disliked,
        // we continue retrying with the best relay from the full list.
        final relayPool =
            filteredReachableRelays.isNotEmpty ? filteredReachableRelays : reachableRelayUrls;

        if (relayPool.isEmpty) {
          throw FailedToPickUserRelay('User ${actionSource.pubkey} relay pool is empty.');
        }

        final chosenRelayUrl =
            _getFirstActiveRelayUrl(relayPool) ?? await _selectRelayUrlForOtherUser(relayPool);
        Logger.log(
          '$sessionPrefix[RELAY] User ${actionSource.pubkey} read relay selected: $chosenRelayUrl from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
        final chosenRelay =
            await ref.read(relayProvider(chosenRelayUrl, anonymous: actionSource.anonymous).future);
        return {chosenRelay: {}};

      case ActionSourceIndexers():
        final indexerUrls = await ref.read(currentUserIndexersProvider.future);
        if (indexerUrls == null) {
          throw UserIndexersNotFoundException();
        }

        final filteredIndexerUrls = _filterOutDislikedRelayUrls(indexerUrls, dislikedUrls);

        // If we already tried all indexer relays and they were disliked,
        // we continue retrying with the best relay from the full list.
        final relayPool = filteredIndexerUrls.isNotEmpty ? filteredIndexerUrls : indexerUrls;

        if (relayPool.isEmpty) {
          throw FailedToPickIndexerRelay();
        }

        final chosenIndexerUrl = _getFirstActiveRelayUrl(relayPool) ?? relayPool.random!;
        Logger.log(
          '$sessionPrefix[RELAY] Indexer relay selected: $chosenIndexerUrl from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
        final chosenRelay = await ref
            .read(relayProvider(chosenIndexerUrl, anonymous: actionSource.anonymous).future);
        return {chosenRelay: {}};

      case ActionSourceRelayUrl():
        Logger.log(
          '$sessionPrefix[RELAY] Direct relay URL selected: ${actionSource.url}',
        );
        final chosenRelay = await ref
            .read(relayProvider(actionSource.url, anonymous: actionSource.anonymous).future);
        return {chosenRelay: {}};

      case ActionSourceOptimalRelays():
        final relays = await ref.read(optimalUserRelaysServiceProvider).fetch(
              masterPubkeys: actionSource.masterPubkeys,
              strategy: actionSource.strategy,
              failedRelayUrls: dislikedUrls.urls.toList(),
            );
        final result = <IonConnectRelay, Set<String>>{};

        for (final url in relays.keys) {
          final relay =
              await ref.read(relayProvider(url, anonymous: actionSource.anonymous).future);
          result[relay] = relays[url]!.toSet();
        }
        Logger.log(
          '$sessionPrefix[RELAY] Optimal relays selected: $result, disliked: ${dislikedUrls.urls}',
        );
        return result;
    }
  }

  Future<List<UserRelay>> _getCurrentUserRankedRelays() async {
    final relays = await ref.read(rankedCurrentUserRelaysProvider.future);
    if (relays.isEmpty) {
      throw UserRelaysNotFoundException();
    }
    return relays;
  }

  Future<UserRelaysEntity> _getCurrentUserReachableRelays() async {
    final pubkey = ref.read(currentPubkeySelectorProvider);
    if (pubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }
    return _getUserReachableRelays(pubkey);
  }

  Future<UserRelaysEntity> _getUserReachableRelays(String pubkey) async {
    final relays =
        await ref.read(userRelaysManagerProvider.notifier).fetchReachableRelays([pubkey]);
    if (relays.isEmpty) {
      throw UserRelaysNotFoundException(pubkey);
    }
    return relays.first;
  }

  /// Filters provided user relay urls by excluding those that are disliked.
  ///
  /// This is a mechanism for retry on another relay if something happened on a chosen one.
  /// For example, if an error happened during read / write operation, on retry, we should try another relay.
  List<String> _filterOutDislikedRelayUrls(
    List<String> relayUrls,
    DislikedRelayUrlsCollection dislikedRelaysUrls,
  ) {
    return relayUrls.toSet().difference(dislikedRelaysUrls.urls).toList();
  }

  /// Returns the first found active relay url for the given relay url list.
  ///
  /// This is a mechanism to reuse already established connections.
  /// Active relay is a relay that is currently connected and available for use.
  String? _getFirstActiveRelayUrl(List<String> userRelayUrls) {
    final activeRelaysSet = ref.read(activeRelaysProvider);
    if (activeRelaysSet.isEmpty) return null;

    return userRelayUrls.firstWhereOrNull(activeRelaysSet.contains);
  }

  /// Selects a relay url that might be used to fetch other user's content
  /// based on the current user's ranked relevant relays.
  Future<String> _selectRelayUrlForOtherUser(List<String> userRelayUrls) async {
    if (userRelayUrls.length == 1) return userRelayUrls.first;

    final rankedRelevantCurrentUserRelaysUrls =
        await ref.read(rankedRelevantCurrentUserRelaysUrlsProvider.future);

    final optimalUserRelayUrl =
        rankedRelevantCurrentUserRelaysUrls.firstWhereOrNull(userRelayUrls.contains);

    if (optimalUserRelayUrl != null) {
      return optimalUserRelayUrl;
    }

    final randomUserRelayUrl = userRelayUrls.random;
    if (randomUserRelayUrl == null) {
      throw FailedToPickUserRelay();
    }

    return randomUserRelayUrl;
  }

  List<UserRelay> _filterWriteRelays(UserRelaysEntity relayEntity) {
    return relayEntity.data.list.where((relay) => relay.write).toList();
  }
}
