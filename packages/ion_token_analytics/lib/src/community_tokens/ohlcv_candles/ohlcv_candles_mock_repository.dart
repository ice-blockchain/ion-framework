// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math' as math;

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesMockRepository implements OhlcvCandlesRepository {
  @override
  Future<List<OhlcvCandle>> loadOhlcvCandles({
    required String externalAddress,
    required String interval,
    int limit = 60,
    int offset = 0,
  }) async {
    return _generateMockCandles(limit);
  }

  @override
  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) async {
    return NetworkSubscription(stream: const Stream<List<OhlcvCandle>>.empty(), close: () async {});
  }

  List<OhlcvCandle> _generateMockCandles(int count) {
    final now = DateTime.now();
    const basePrice = 0.00033;
    const waveAmplitude = 0.000015;
    const microWave = 0.000004;
    const baseVolume = 1000.0;

    var previousClose = basePrice;
    final candles = <OhlcvCandle>[];

    for (var i = 0; i < count; i++) {
      final progress = i / count;
      final trend = math.sin(progress * math.pi * 2) * waveAmplitude;
      final wobble = math.sin(i * 1.7) * microWave;

      final targetClose = (basePrice + trend + wobble).clamp(0.0002, 0.001);
      final open = previousClose;
      final close = targetClose;
      final high = math.max(open, close) + microWave.abs();
      final low = math.min(open, close) - microWave.abs();
      final volume = baseVolume + (math.Random().nextDouble() * 500);

      final timestamp =
          now.subtract(Duration(minutes: (count - i) * 15)).millisecondsSinceEpoch * 1000;

      candles.add(
        OhlcvCandle(
          timestamp: timestamp,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );

      previousClose = close;
    }

    return candles;
  }
}
