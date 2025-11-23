// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesMockHandler {
  static final _rnd = Random();

  Future<NetworkSubscription<T>> handleSubscription<T>() async {
    final controller = StreamController<T>();
    Timer? timer;

    // 1) Emit initial snapshot (individual candles)
    final snapshot = _generateSnapshot();
    for (final candle in snapshot) {
      if (!controller.isClosed) {
        controller.add(candle.toJson() as T);
      }
    }

    // 3) Emit periodic updates
    var lastCandle = snapshot.last;
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final next = _generateNextCandle(lastCandle);
      lastCandle = next; // Update last candle for next iteration
      if (!controller.isClosed) {
        controller.add(next.toJson() as T);
      }
    });

    return NetworkSubscription<T>(
      stream: controller.stream,
      close: () async {
        timer?.cancel();
        await controller.close();
      },
    );
  }

  // --- Mock Data Generation Logic ---

  List<OhlcvCandle> _generateSnapshot() {
    final now = DateTime.now().millisecondsSinceEpoch;

    return List.generate(50, (i) {
      final ts = now - (50 - i) * 60000;
      final open = 0.03 + _rnd.nextDouble() * 0.003;
      final close = open + (_rnd.nextDouble() - 0.5) * 0.002;

      return OhlcvCandle(
        timestamp: ts,
        open: open,
        high: open + _rnd.nextDouble() * 0.002,
        low: open - _rnd.nextDouble() * 0.002,
        close: close,
        volume: 20 + _rnd.nextDouble() * 20,
      );
    });
  }

  OhlcvCandle _generateNextCandle(OhlcvCandle last) {
    // 90% chance to update current candle, 10% chance to start new candle
    final isNewCandle = _rnd.nextDouble() > 0.9;

    if (isNewCandle) {
      final ts = last.timestamp + 60000;
      return OhlcvCandle(
        timestamp: ts,
        open: last.close,
        high: last.close + _rnd.nextDouble() * 0.002,
        low: last.close - _rnd.nextDouble() * 0.002,
        close: last.close + (_rnd.nextDouble() - 0.5) * 0.003,
        volume: 20 + _rnd.nextDouble() * 20,
      );
    } else {
      // Update existing candle (e.g. price change, volume increase)
      return last.copyWith(
        close: last.close + (_rnd.nextDouble() - 0.5) * 0.001,
        high: max(last.high, last.close + 0.001),
        low: min(last.low, last.close - 0.001),
        volume: last.volume + _rnd.nextDouble() * 5,
      );
    }
  }
}
