// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/models.dart';
import 'package:ion_token_analytics/src/community_tokens/trading_stats/trading_stats_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class TradingStatsRepositoryImpl implements TradingStatsRepository {
  TradingStatsRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats(
    String ionConnectAddress,
  ) async {
    final subscription = await _client.subscribeSse<Map<String, dynamic>>(
      '/v1sse/community-tokens/$ionConnectAddress/trading-stats',
    );

    final stream = subscription.stream.where((json) => json.isNotEmpty).map((statsMap) {
      final map = <String, TradingStats>{};

      for (final entry in statsMap.entries) {
        try {
          if (entry.value is Map<String, dynamic>) {
            map[entry.key] = TradingStats.fromJson(entry.value as Map<String, dynamic>);
          }
        } catch (e) {
          // Skip invalid trading stats entries
        }
      }
      return map;
    });

    return NetworkSubscription(stream: stream, close: subscription.close);
  }
}
