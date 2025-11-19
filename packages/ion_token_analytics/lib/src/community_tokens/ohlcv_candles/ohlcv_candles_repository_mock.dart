// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:math';

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';
import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/ohlcv_candles_repository.dart';
import 'package:ion_token_analytics/src/core/network_client.dart';

class OhlcvCandlesRepositoryMock implements OhlcvCandlesRepository {
  static final _rnd = Random();

  List<OhlcvCandle> _generateSnapshot() {
    final now = DateTime.now().millisecondsSinceEpoch;

    return List.generate(20, (i) {
      final ts = now - (20 - i) * 60000;
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
    final ts = last.timestamp + 60000;

    return OhlcvCandle(
      timestamp: ts,
      open: last.close,
      high: last.close + _rnd.nextDouble() * 0.002,
      low: last.close - _rnd.nextDouble() * 0.002,
      close: last.close + (_rnd.nextDouble() - 0.5) * 0.003,
      volume: 20 + _rnd.nextDouble() * 20,
    );
  }

  @override
  Future<NetworkSubscription<List<OhlcvCandle>>> subscribeToOhlcvCandles({
    required String ionConnectAddress,
    required String interval,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final controller = StreamController<List<OhlcvCandle>>();

    var snapshot = _generateSnapshot();
    controller.add(List<OhlcvCandle>.from(snapshot));

    Timer.periodic(const Duration(seconds: 2), (_) {
      final next = _generateNextCandle(snapshot.last);

      snapshot = [...snapshot, next];
      if (snapshot.length > 20) snapshot.removeAt(0);

      // Emit updated snapshot (after applying new candle)
      controller.add(List<OhlcvCandle>.from(snapshot));
    });

    return NetworkSubscription(stream: controller.stream, close: () async => controller.close());
  }
}
