// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/relay_proxy_domains_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart' hide requestEvents;
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/disliked_relay_urls_collection.f.dart';
import 'package:ion/app/features/ion_connect/providers/relays/active_relays_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_disliked_connect_urls_provider.r.dart';
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

  static const Duration _directConnectTimeout = Duration(seconds: 20);
  static const Duration _activeDirectPrecheckTimeout = Duration(seconds: 5);
  static const Duration _directProbeCacheTtl = Duration(seconds: 10);
  final Map<String, ({String? winnerUrl, DateTime checkedAt})> _directProbeCache = {};
  final Map<String, Future<String?>> _inFlightDirectProbes = {};

  /// Phase 1: direct-only pool probe.
  ///
  /// Uses lightweight socket reachability checks (no proxy candidates) and
  /// returns the first direct winner. Probe relays are always closed and this
  /// phase never authenticates.
  Future<String?> _pickDirectRelayUrlFromPool(
    List<String> relayPool, {
    required String sessionPrefix,
  }) async {
    if (relayPool.isEmpty) return null;

    // Prefer an already-active relay first.
    final activeUrl = _getFirstActiveRelayUrl(relayPool);
    final orderedPool = activeUrl != null
        ? <String>[activeUrl, ...relayPool.where((u) => u != activeUrl)]
        : relayPool;

    final probeKey = orderedPool.join('|');
    final now = DateTime.now();
    final cachedProbe = _directProbeCache[probeKey];
    if (cachedProbe != null && now.difference(cachedProbe.checkedAt) < _directProbeCacheTtl) {
      return cachedProbe.winnerUrl;
    }

    final inFlightProbe = _inFlightDirectProbes[probeKey];
    if (inFlightProbe != null) {
      return inFlightProbe;
    }

    if (activeUrl != null) {
      final activePrecheckError = await _tryDirectSocketReachability(
        activeUrl,
        timeout: _activeDirectPrecheckTimeout,
      );

      if (activePrecheckError == null) {
        _directProbeCache[probeKey] = (
          winnerUrl: activeUrl,
          checkedAt: DateTime.now(),
        );
        return activeUrl;
      }

      Logger.log(
        '$sessionPrefix[RELAY] Active direct pre-check failed: $activeUrl; $activePrecheckError',
      );
    }

    final probeFuture = _probeDirectRelayUrlFromOrderedPool(
      orderedPool,
      sessionPrefix: sessionPrefix,
    ).then((winnerUrl) {
      _directProbeCache[probeKey] = (
        winnerUrl: winnerUrl,
        checkedAt: DateTime.now(),
      );
      return winnerUrl;
    }).whenComplete(() {
      _inFlightDirectProbes.remove(probeKey);
    });

    _inFlightDirectProbes[probeKey] = probeFuture;
    return probeFuture;
  }

  /// Lightweight direct-only reachability probe without createRelay side effects.
  ///
  /// This avoids mutating reachability stats, triggering internet checks, and
  /// failover telemetry during picker probing.
  Future<Object?> _tryDirectSocketReachability(
    String relayUrl, {
    required Duration timeout,
  }) async {
    final directConnectUri =
        ref.read(relayConnectUrisProvider(relayUrl, includeProxies: false)).first;
    final socket = WebSocket(directConnectUri, timeout: timeout);
    final relay = IonConnectRelay(
      url: relayUrl,
      connectUrl: directConnectUri.toString(),
      socket: socket,
    );

    try {
      final connectionState = await socket.connection.firstWhere(
        (state) => state is Connected || state is Reconnected || state is Disconnected,
      );

      if (connectionState is Disconnected) {
        return connectionState.error ?? Exception('Relay disconnected during direct probe');
      }

      return null;
    } catch (e) {
      return e;
    } finally {
      relay.close();
    }
  }

  Future<String?> _probeDirectRelayUrlFromOrderedPool(
    List<String> orderedPool, {
    required String sessionPrefix,
  }) async {
    final winnerCompleter = Completer<String?>();
    var pending = 0;

    // Probe all direct relays in parallel.
    for (final url in orderedPool) {
      pending++;
      unawaited(() async {
        final directProbeError = await _tryDirectSocketReachability(
          url,
          timeout: _directConnectTimeout,
        );
        if (directProbeError == null) {
          if (!winnerCompleter.isCompleted) {
            winnerCompleter.complete(url);
          }
        } else {
          Logger.log(
            '$sessionPrefix[RELAY] Direct relay connect failed: $url; $directProbeError',
          );
        }
        pending--;
        if (pending == 0 && !winnerCompleter.isCompleted) {
          winnerCompleter.complete(null);
        }
      }());
    }

    return winnerCompleter.future.timeout(
      _directConnectTimeout,
      onTimeout: () {
        return null;
      },
    );
  }

  /// Returns a relay from a pool using two phases:
  /// 1) direct-only probing across the full pool and connect direct winner
  /// 2) if no direct winner, use [fallbackRelayUrl] with proxy-enabled [relayProvider]
  Future<IonConnectRelay> _getRelayFromPool(
    List<String> relayPool, {
    required bool anonymous,
    required String sessionPrefix,
    required String fallbackRelayUrl,
  }) async {
    if (relayPool.length == 1) {
      return await ref.read(
        relayProvider(
          fallbackRelayUrl,
          anonymous: anonymous,
        ).future,
      );
    }

    final directRelayUrl = await _pickDirectRelayUrlFromPool(
      relayPool,
      sessionPrefix: sessionPrefix,
    );

    if (directRelayUrl != null) {
      // Build a real relay (including auth) only for the direct winner.
      return await ref.read(
        relayProvider(
          directRelayUrl,
          anonymous: anonymous,
          allowProxy: false,
        ).future,
      );
    }

    Logger.warning(
      '$sessionPrefix[RELAY] No direct relays reachable in pool. Falling back to proxy-enabled strategy with relay: $fallbackRelayUrl',
    );
    return await ref.read(
      relayProvider(
        fallbackRelayUrl,
        anonymous: anonymous,
      ).future,
    );
  }

  Future<Map<IonConnectRelay, Set<String>>> getActionSourceRelays(
    ActionSource actionSource, {
    required ActionType actionType,
    DislikedRelayUrlsCollection dislikedUrls = const DislikedRelayUrlsCollection({}),
    String? sessionId,
  }) async {
    return switch (actionType) {
      ActionType.read =>
        _getReadActionSourceRelays(actionSource, dislikedUrls: dislikedUrls, sessionId: sessionId),
      ActionType.write =>
        _getWriteActionSourceRelays(actionSource, dislikedUrls: dislikedUrls, sessionId: sessionId),
    };
  }

  Future<Map<IonConnectRelay, Set<String>>> _getWriteActionSourceRelays(
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

      return _getReadActionSourceRelays(
        actionSource,
        dislikedUrls: dislikedUrls,
        sessionId: sessionId,
      );
    }

    final fallbackRelayUrl =
        _getFirstActiveRelayUrl(filteredWriteRelayUrls) ?? filteredWriteRelayUrls.random!;
    final chosenRelay = await _getRelayFromPool(
      filteredWriteRelayUrls,
      anonymous: actionSource.anonymous,
      sessionPrefix: sessionPrefix,
      fallbackRelayUrl: fallbackRelayUrl,
    );
    Logger.log(
      '$sessionPrefix[RELAY] Write relay selected: ${chosenRelay.url} from pool: $filteredWriteRelayUrls, disliked: ${dislikedUrls.urls}',
    );
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

        final fallbackRelayUrl = _getFirstActiveRelayUrl(relayPool) ?? relayPool.first;
        final chosenRelay = await _getRelayFromPool(
          relayPool,
          anonymous: actionSource.anonymous,
          sessionPrefix: sessionPrefix,
          fallbackRelayUrl: fallbackRelayUrl,
        );
        Logger.log(
          '$sessionPrefix[RELAY] Current user read relay selected: ${chosenRelay.url} from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
        return {
          chosenRelay: {},
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

        final fallbackRelayUrl =
            _getFirstActiveRelayUrl(relayPool) ?? await _selectRelayUrlForOtherUser(relayPool);
        final chosenRelay = await _getRelayFromPool(
          relayPool,
          anonymous: actionSource.anonymous,
          sessionPrefix: sessionPrefix,
          fallbackRelayUrl: fallbackRelayUrl,
        );
        Logger.log(
          '$sessionPrefix[RELAY] User read relay selected: ${chosenRelay.url} from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
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

        final fallbackRelayUrl = _getFirstActiveRelayUrl(relayPool) ?? relayPool.random!;
        final chosenRelay = await _getRelayFromPool(
          relayPool,
          anonymous: actionSource.anonymous,
          sessionPrefix: sessionPrefix,
          fallbackRelayUrl: fallbackRelayUrl,
        );
        Logger.log(
          '$sessionPrefix[RELAY] Indexer relay selected: ${chosenRelay.url} from pool: $relayPool, disliked: ${dislikedUrls.urls}',
        );
        return {chosenRelay: {}};

      case ActionSourceRelayUrl():
        _allowDirectConnectUrlRetry(actionSource.url);
        final chosenRelay = await ref
            .read(relayProvider(actionSource.url, anonymous: actionSource.anonymous).future);
        return {chosenRelay: {}};

      case ActionSourceOptimalRelays():
        final relays = await ref.read(optimalUserRelaysServiceProvider).fetch(
              masterPubkeys: actionSource.masterPubkeys,
              strategy: actionSource.strategy,
              failedRelayUrls: dislikedUrls.urls.toList(),
            );

        final relayFutures = relays.entries.map((userRelayEntry) async {
          _allowDirectConnectUrlRetry(userRelayEntry.key);
          final ionConnectRelay = await ref
              .read(relayProvider(userRelayEntry.key, anonymous: actionSource.anonymous).future);
          return MapEntry(ionConnectRelay, userRelayEntry.value.toSet());
        }).toList();

        final relayResults = await Future.wait(relayFutures);
        final result = Map.fromEntries(relayResults);

        Logger.log(
          '$sessionPrefix[RELAY] Optimal relays selected: {${result.entries.map((e) => "'${e.key.url}': ${e.value}").join(', ')}}, disliked: ${dislikedUrls.urls}',
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

  /// Allows one fresh direct attempt by removing only the normalized direct
  /// connect URL from the per-relay disliked connect URL set.
  void _allowDirectConnectUrlRetry(String logicalRelayUrl) {
    final directConnectUrl = ref
        .read(
          relayConnectUrisProvider(logicalRelayUrl, includeProxies: false),
        )
        .first
        .toString();
    ref.read(relayDislikedConnectUrlsProvider(logicalRelayUrl).notifier).remove(directConnectUrl);
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
