// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class OhlcvCandlesRepository {
  Future<List<OhlcvCandle>> loadOhlcvCandles({
    required String externalAddress,
    required String interval,
    int limit = 60,
    int offset = 0,
  });

  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  });
}
