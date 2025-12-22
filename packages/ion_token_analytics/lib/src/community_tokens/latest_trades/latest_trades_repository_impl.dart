// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion_token_analytics/src/community_tokens/latest_trades/latest_trades_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class LatestTradesRepositoryImpl implements LatestTradesRepository {
  LatestTradesRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<List<LatestTrade>> fetchLatestTrades(
    String ionConnectAddress, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/v1/community-tokens/$ionConnectAddress/latest-trades',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.isEmpty) {
        return [];
      }

      final result = <LatestTrade>[];

      for (var i = 0; i < response.length; i++) {
        final entity = response[i];
        if (entity is! Map<String, dynamic>) {
          continue;
        }

        try {
          result.add(LatestTrade.fromJson(entity));
        } catch (_) {}
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<NetworkSubscription<List<LatestTradeBase>>> subscribeToLatestTrades(
    String ionConnectAddress,
  ) async {
    try {
      // Subscribe to the raw event stream.
      final subscription = await _client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/$ionConnectAddress/latest-trades',
      );

      // Each SSE event carries a "Type" and optional "Data" payload. If "Type"
      // is "eose" it indicates end of the initial stream. Otherwise, the "Data"
      // field contains either a full LatestTrade or a partial update (patch).
      // Convert each event into a batch of LatestTradeBase.
      final stream = subscription.stream.map((event) {
        // Marker / EOSE handling:
        // - The HTTP client may convert Go `Data: nil` into an empty map `{}`.
        // - The server may also send an explicit `{Type: "eose", Data: nil}`.
        if (event.isEmpty) {
          return <LatestTradeBase>[];
        }

        final type = (event['Type'] ?? event['type']) as String?;
        if (type == 'eose') {
          // End of initial load: emit an empty batch.
          return <LatestTradeBase>[];
        }

        // Determine the JSON payload to decode. Some backends send a top-level
        // object (no Data key) while others wrap it in a Data key. Fallback to
        // the full event if no Data key is present.
        final data = event.containsKey('Data')
            ? event['Data']
            : (event.containsKey('data') ? event['data'] : event);
        if (data is! Map<String, dynamic>) {
          // Unexpected payload; ignore.
          return <LatestTradeBase>[];
        }

        // Try to decode a full LatestTrade first. If that fails, decode a patch.
        try {
          final trade = LatestTrade.fromJson(data);
          return <LatestTradeBase>[trade];
        } catch (_) {
          try {
            return <LatestTradeBase>[LatestTradePatch.fromJson(data)];
          } catch (_) {
            // Unknown event structure; ignore.
            return <LatestTradeBase>[];
          }
        }
      });

      return NetworkSubscription(stream: stream, close: subscription.close);
    } catch (e) {
      rethrow;
    }
  }
}
