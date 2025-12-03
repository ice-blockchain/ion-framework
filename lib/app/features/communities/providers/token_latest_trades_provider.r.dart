// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_latest_trades_provider.r.g.dart';

@riverpod
class TokenLatestTrades extends _$TokenLatestTrades {
  late int _limit;
  List<LatestTrade> _currentTrades = [];

  @override
  Stream<List<LatestTrade>> build(
    String externalAddress, {
    int limit = 10,
    int offset = 0,
  }) async* {
    _limit = limit;

    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    // 1. Fetch initial history via REST
    final initialTrades = await client.communityTokens.latestTradesRepository.fetchLatestTrades(
      externalAddress,
      limit: limit,
      offset: offset,
    );
    _currentTrades = initialTrades;
    yield _currentTrades;

    // 2. Subscribe to real-time updates
    final subscription =
        await client.communityTokens.latestTradesRepository.subscribeToLatestTrades(
      externalAddress,
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

        if (newTrade is LatestTradePatch) {
          final patchedTrade = existTrade.merge(newTrade);

          _currentTrades = List.of(_currentTrades);
          _currentTrades[existIndex] = patchedTrade;
        } else if (newTrade is LatestTrade) {
          _currentTrades = List.of(_currentTrades);
          _currentTrades[existIndex] = newTrade;
        }
      } else {
        if (newTrade is LatestTrade) {
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
      final moreTrades = await client.communityTokens.latestTradesRepository.fetchLatestTrades(
        externalAddress,
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
