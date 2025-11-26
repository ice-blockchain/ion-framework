// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart' as analytics;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_latest_trades_provider.r.g.dart';

@riverpod
class TokenLatestTrades extends _$TokenLatestTrades {
  late String _masterPubkey;
  late int _limit;
  List<analytics.LatestTrade> _currentTrades = [];

  @override
  Stream<List<analytics.LatestTrade>> build(
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

    // 3. Listen to updates and prepend them
    await for (final newTrade in subscription.stream) {
      final existIndex = _currentTrades.indexWhere(
        (element) =>
            element.position.createdAt == newTrade.position?.createdAt &&
            element.position.addresses.ionConnect == newTrade.position?.addresses?.ionConnect,
      );

      if (existIndex >= 0) {
        final existTrade = _currentTrades[existIndex];

        if (newTrade is analytics.LatestTradePatch) {
          final patchedTrade = existTrade.merge(newTrade);

          _currentTrades = List.of(_currentTrades);
          _currentTrades[existIndex] = patchedTrade;
        } else if (newTrade is analytics.LatestTrade) {
          _currentTrades = List.of(_currentTrades);
          _currentTrades[existIndex] = newTrade;
        }
      } else {
        if (newTrade is analytics.LatestTrade) {
          _currentTrades = [newTrade, ..._currentTrades];
        }
      }
      yield _currentTrades;
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
