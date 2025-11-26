// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/trading_stats/models/models.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class TradingStatsRepository {
  Future<NetworkSubscription<Map<String, TradingStats>>> subscribeToTradingStats(
    String ionConnectAddress,
  );
}
