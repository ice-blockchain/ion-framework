// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesRepositoryImpl implements OhlcvCandlesRepository {
  OhlcvCandlesRepositoryImpl(this._client);

  final NetworkClient _client;

  @override
  Future<NetworkSubscription<OhlcvCandle>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) async {
    // Subscribe to raw stream (dynamic)
    final rawSubscription = await _client.subscribe<dynamic>(
      '/community-tokens/$ionConnectAddress/ohlcv',
      queryParameters: {'interval': interval},
    );

    // Apply transformer
    final transformedStream = rawSubscription.stream.map((event) => event as OhlcvCandle);

    return NetworkSubscription(stream: transformedStream, close: rawSubscription.close);
  }
}
