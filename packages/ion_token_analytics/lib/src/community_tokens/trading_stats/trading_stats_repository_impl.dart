// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/trading_stats_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TradingStatsRepositoryImpl implements TradingStatsRepository {
  TradingStatsRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats(
    String externalAddress,
  ) async {
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/$externalAddress/trading-stats',
    );
    final stream = subscription.stream.map((e) {
      final tradingStatsMap = <String, TradingStats>{};
      e.forEach((key, value) {
        tradingStatsMap[key] = TradingStats.fromJson(value as Map<String, dynamic>);
      });
      return tradingStatsMap;
    });

    return NetworkSubscription<Map<String, TradingStats>>(
      stream: stream,
      close: subscription.close,
    );
  }
}
