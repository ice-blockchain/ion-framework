// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesRepositoryImpl implements OhlcvCandlesRepository {
  OhlcvCandlesRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<OhlcvCandle>> subscribeToOhlcvCandles({
    required String externalAddress,
    required String interval,
  }) async {
    try {
      final subscription = await _client.subscribeSse<Map<String, dynamic>>(
        '/v1sse/community-tokens/$externalAddress/ohlcv',
        queryParameters: {'interval': interval},
      );
      final stream = subscription.stream.map((json) {
        final data = OhlcvCandle.fromJson(json);
        return data;
      });

      return NetworkSubscription(stream: stream, close: subscription.close);
    } catch (e) {
      rethrow;
    }
  }
}
