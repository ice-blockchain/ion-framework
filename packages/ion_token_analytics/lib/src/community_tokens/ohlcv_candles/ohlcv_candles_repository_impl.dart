// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesRepositoryImpl implements OhlcvCandlesRepository {
  OhlcvCandlesRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) async {
    try {
      // Subscribe to the raw event stream
      final subscription = await _client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/$ionConnectAddress/ohlcv',
        queryParameters: {'interval': interval},
      );

      // Each SSE event carries a "Type" and optional "Data" payload.  If "Type"
      // is "eose" it indicates end of the initial stream.  Otherwise, the
      // "Data" field contains an OHLCV candle.  Convert each event into a batch of OhlcvCandle.
      final stream = subscription.stream.map((event) {
        // Marker / EOSE handling:
        // - The HTTP client may convert Go `Data: nil` into an empty map `{}`.
        // - The server may also send an explicit `{Type: "eose", Data: nil}`.
        if (event.isEmpty) {
          return <OhlcvCandle>[];
        }

        final type = (event['Type'] ?? event['type']) as String?;
        if (type == 'eose') {
          // End of initial load: emit an empty batch.
          return <OhlcvCandle>[];
        }

        // Determine the JSON payload to decode. Some backends send a top-level
        // object (no Data key) while others wrap it in a Data key.  Fallback to
        // the full event if no Data key is present.
        final data = event.containsKey('Data')
            ? event['Data']
            : (event.containsKey('data') ? event['data'] : event);
        if (data is! Map<String, dynamic>) {
          // Unexpected payload; ignore.
          return <OhlcvCandle>[];
        }

        try {
          final candle = OhlcvCandle.fromJson(data);
          return <OhlcvCandle>[candle];
        } catch (_) {
          // Unknown event structure; ignore.
          return <OhlcvCandle>[];
        }
      });

      return NetworkSubscription(stream: stream, close: subscription.close);
    } catch (e) {
      rethrow;
    }
  }
}
