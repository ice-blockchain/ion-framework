// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class LatestTradesRepository {
  Future<NetworkSubscription<List<LatestTrade>>> subscribeToLatestTrades(String ionConnectAddress);
}
