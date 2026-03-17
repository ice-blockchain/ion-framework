// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_interval_utils.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_olhcv_candles_provider.r.g.dart';

const _initialWaitPeriod = Duration(milliseconds: 400);
const _maxCandles = 50;
const _tickBuffer = Duration(seconds: 5);

@riverpod
Stream<List<OhlcvCandle>> tokenOhlcvCandles(
  Ref ref,
  String externalAddress,
  String interval,
) async* {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);

  // 1. Load initial candles
  final initialCandles = await client.communityTokens.loadOhlcvCandles(
    externalAddress: externalAddress,
    interval: interval,
  );

  // 2. Subscribe to realtime updates
  final subscription = await client.communityTokens.subscribeToOhlcvCandles(
    ionConnectAddress: externalAddress,
    interval: interval,
  );

  ref.onDispose(subscription.close);

  final currentCandles = List<OhlcvCandle>.from(initialCandles)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // 3. Merge SSE stream with periodic tick markers (null = tick).
  //    Ticks fire at each interval boundary + 5s buffer so the downstream
  //    normalizer extends the chart to "now" even when BE is silent.
  final tickStream = _withIntervalTicks(subscription.stream, interval);
  final iterator = StreamIterator(tickStream);
  ref.onDispose(iterator.cancel);

  // 4. Wait briefly for any early SSE update and merge it before first emit
  //    (avoids chart flashing two frames). No ticks fire within 400ms.
  try {
    while (await iterator.moveNext().timeout(_initialWaitPeriod)) {
      final event = iterator.current;
      if (event != null && event.isNotEmpty) {
        _applyBatch(currentCandles, event, interval);
        break;
      }
    }
  } catch (_) {
    // Timeout or SSE error during initial wait — proceed with initial data
  }

  // 5. Emit first frame (initial data + any early realtime merged)
  _sortAndTrim(currentCandles, _maxCandles);
  yield List<OhlcvCandle>.from(currentCandles);

  // 6. Process merged stream: null = tick, empty = keepalive, non-empty = real data
  while (await iterator.moveNext()) {
    final event = iterator.current;

    if (event == null) {
      // Tick: re-emit so normalizer extends chart to "now"
      yield List<OhlcvCandle>.from(currentCandles);
      continue;
    }

    if (event.isEmpty) continue; // SSE keepalive — skip

    // Real data from BE
    _applyBatch(currentCandles, event, interval);
    _sortAndTrim(currentCandles, _maxCandles);
    yield currentCandles;
  }
}

// Wraps source stream, injecting `null` tick markers at each interval
// boundary + tickBuffer. Timer resets only on real (non-empty) data.
// Used to keep the chart extending over time when BE sends no updates.
Stream<List<OhlcvCandle>?> _withIntervalTicks(
  Stream<List<OhlcvCandle>> source,
  String interval,
) {
  final controller = StreamController<List<OhlcvCandle>?>();
  Timer? tickTimer;

  void scheduleNextTick() {
    tickTimer?.cancel();
    tickTimer = Timer(timeUntilNextSlot(interval, buffer: _tickBuffer), () {
      if (!controller.isClosed) {
        controller.add(null);
        scheduleNextTick();
      }
    });
  }

  final sub = source.listen(
    (batch) {
      controller.add(batch);
      if (batch.isNotEmpty) scheduleNextTick();
    },
    onError: controller.addError,
    onDone: () {
      tickTimer?.cancel();
      controller.close();
    },
  );

  controller.onCancel = () {
    tickTimer?.cancel();
    sub.cancel();
  };

  scheduleNextTick();
  return controller.stream;
}

void _applyBatch(
  List<OhlcvCandle> candles,
  List<OhlcvCandle> batch,
  String interval,
) {
  for (final candle in batch) {
    final last = candles.isNotEmpty ? candles.last : null;
    final sameSlot = last != null &&
        areSameTimeSlot(
          candle.timestamp.toDateTime,
          last.timestamp.toDateTime,
          interval,
        );
    if (sameSlot) {
      candles[candles.length - 1] = candle;
    } else {
      candles.add(candle);
    }
  }
}

void _sortAndTrim(List<OhlcvCandle> candles, int maxCandles) {
  candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  if (candles.length > maxCandles) {
    candles.removeRange(0, candles.length - maxCandles);
  }
}
