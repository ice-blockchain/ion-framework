// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

abstract class OhlcvCandlesRepository {
  Future<NetworkSubscription<OhlcvCandle>> subscribeToOhlcvCandles({
    required String externalAddress,
    required String interval,
  });
}
