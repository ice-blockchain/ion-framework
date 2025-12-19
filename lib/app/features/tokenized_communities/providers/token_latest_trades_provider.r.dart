// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_latest_trades_provider.r.g.dart';

@riverpod
class TokenLatestTrades extends _$TokenLatestTrades {
  late String _masterPubkey;
  late int _limit;
  List<LatestTrade> _currentTrades = [];

  @override
  Stream<List<LatestTrade>> build(
    String masterPubkey, {
    int limit = 10,
    int offset = 0,
  }) async* {
    _masterPubkey = masterPubkey;
    _limit = limit;

    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    // 1. Fetch initial history via REST
    final initialTrades = await client.communityTokens.fetchLatestTrades(
      ionConnectAddress: masterPubkey,
      limit: limit,
      offset: offset,
    );
    _currentTrades = initialTrades;
    yield _currentTrades;

    // 2. Subscribe to real-time updates
    final subscription = await client.communityTokens.subscribeToLatestTrades(
      ionConnectAddress: masterPubkey,
    );

    ref.onDispose(subscription.close);

    // 3. Listen to updates and prepend them.
    // Contract: this endpoint only emits new immutable trades (transactions).
    // Ignore any partial/patch entities on the provider layer.
    await for (final updates in subscription.stream) {
      if (updates.isEmpty) continue;

      var changed = false;

      for (final update in updates) {
        if (update is! LatestTrade) {
          // Patches are not expected for this endpoint. Ignore.
          continue;
        }

        final createdAt = update.position.createdAt;
        final ionConnect = update.position.addresses.ionConnect;

        // De-dupe on reconnect / retries.
        final existingIndex = _currentTrades.indexWhere(
          (t) => t.position.createdAt == createdAt && t.position.addresses.ionConnect == ionConnect,
        );

        if (existingIndex == 0) {
          // Already at the top.
          continue;
        }

        _currentTrades = List.of(_currentTrades);

        if (existingIndex >= 0) {
          _currentTrades.removeAt(existingIndex);
        }

        _currentTrades.insert(0, update);

        // Keep a fixed-size window of the latest trades.
        if (_currentTrades.length > _limit) {
          _currentTrades = _currentTrades.take(_limit).toList(growable: false);
        }

        changed = true;
      }

      if (changed) {
        yield _currentTrades;
      }
    }
  }

  Future<void> loadMore() async {
    if (_currentTrades.isEmpty) return;

    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    final currentCount = _currentTrades.length;

    try {
      final moreTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _limit,
        offset: currentCount,
      );

      if (moreTrades.isNotEmpty) {
        _currentTrades = [..._currentTrades, ...moreTrades];
        state = AsyncValue.data(_currentTrades);
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading more trades');
    }
  }
}
