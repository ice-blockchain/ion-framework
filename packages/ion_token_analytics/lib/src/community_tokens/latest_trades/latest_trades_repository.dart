// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

abstract class LatestTradesRepository {
  Future<List<LatestTrade>> fetchLatestTrades(
    String ionConnectAddress, {
    int limit = 10,
    int offset = 0,
  });

  Future<NetworkSubscription<LatestTradeBase>> subscribeToLatestTrades(String ionConnectAddress);
}
