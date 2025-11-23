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

  @override
  Future<List<analytics.LatestTrade>> build(
    String masterPubkey, {
    int limit = 10,
    int offset = 0,
  }) async {
    _masterPubkey = masterPubkey;
    _limit = limit;

    final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

    // 1. Fetch initial history via REST
    final initialTrades = await client.communityTokens.fetchLatestTrades(
      ionConnectAddress: masterPubkey,
      limit: limit,
      offset: offset,
    );

    // 2. Subscribe to real-time updates
    await _subscribeToUpdates(client, masterPubkey);

    return initialTrades;
  }

  Future<void> _subscribeToUpdates(
    analytics.IonTokenAnalyticsClient client,
    String masterPubkey,
  ) async {
    final subscription = await client.communityTokens.subscribeToLatestTrades(
      ionConnectAddress: masterPubkey,
    );

    ref.onDispose(subscription.close);

    // Listen to updates and prepend them
    subscription.stream.listen((newTrade) {
      final existIndex = state.valueOrNull?.indexWhere(
            (element) =>
                element.position.createdAt == newTrade.position?.createdAt &&
                element.position.addresses.ionConnect == newTrade.position?.addresses?.ionConnect,
          ) ??
          -1;

      if (existIndex >= 0) {
        final existTrade = state.value![existIndex];
        final existTradeJson = existTrade.toJson()..addAll(newTrade.toJson());
        final patchedTrade = analytics.LatestTrade.fromJson(existTradeJson);

        final currentList = state.value!.toList();
        currentList[existIndex] = patchedTrade;
        state = AsyncValue.data(currentList);
      } else {
        if (newTrade is analytics.LatestTrade) {
          final currentList = state.valueOrNull ?? [];
          state = AsyncValue.data([newTrade, ...currentList]);
        }
      }
    });
  }

  Future<void> loadMore() async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final client = await ref.read(ionTokenAnalyticsClientProvider.future);
    final currentCount = currentList.length;

    try {
      final moreTrades = await client.communityTokens.fetchLatestTrades(
        ionConnectAddress: _masterPubkey,
        limit: _limit,
        offset: currentCount,
      );

      if (moreTrades.isNotEmpty) {
        state = AsyncValue.data([...currentList, ...moreTrades]);
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st, message: 'Error loading more trades');
    }
  }
}
