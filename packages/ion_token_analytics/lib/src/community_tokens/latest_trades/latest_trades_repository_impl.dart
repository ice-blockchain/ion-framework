// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class LatestTradesRepositoryImpl implements LatestTradesRepository {
  LatestTradesRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<List<LatestTrade>> fetchLatestTrades(String ionConnectAddress, {int limit = 10, int offset = 0}) async {
    final response = await _client.get<List<dynamic>>(
      '/community-tokens/$ionConnectAddress/latest-trades',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return response.map((e) => LatestTrade.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<NetworkSubscription<LatestTradePatch>> subscribeToLatestTrades(String ionConnectAddress) async {
    final subscription = await _client.subscribe<Map<String, dynamic>>(
      '/community-tokens/$ionConnectAddress/latest-trades',
    );

    final stream = subscription.stream.map((json) {
      try {
        final data = LatestTrade.fromJson(json);
        return data;
      } catch (_) {
        final patch = LatestTradePatch.fromJson(json);
        return patch;
      }
    });
    return NetworkSubscription(stream: stream, close: subscription.close);
  }
}
