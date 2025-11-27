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
    return _client.subscribe<Map<String, TradingStats>>(
      '/community-tokens/$ionConnectAddress/trading-stats',
    );
  }
}
