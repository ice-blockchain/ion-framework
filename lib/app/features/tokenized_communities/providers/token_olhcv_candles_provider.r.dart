// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_olhcv_candles_provider.r.g.dart';

const _initialWaitPeriod = Duration(milliseconds: 600);
const _maxCandles = 50;

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

  // 3. Wait briefly for any early SSE update and merge it before first emit
  //   (avoids chart flashing two frames).
  final iterator = StreamIterator(subscription.stream);
  ref.onDispose(iterator.cancel);

  try {
    while (await iterator.moveNext().timeout(_initialWaitPeriod)) {
      if (iterator.current.isNotEmpty) {
        _applyBatch(currentCandles, iterator.current, interval);
        break;
      }
    }
  } catch (_) {
    // Timeout or SSE error during initial wait — proceed with initial data
  }

  // 4. Emit first frame (initial data + any early realtime merged)
  _sortAndTrim(currentCandles, _maxCandles);
  yield List<OhlcvCandle>.from(currentCandles);

  // 5. Process remaining realtime updates normally (no timeout)
  while (await iterator.moveNext()) {
    final batch = iterator.current;
    if (batch.isEmpty) {
      yield currentCandles;
      continue;
    }
    _applyBatch(currentCandles, batch, interval);
    _sortAndTrim(currentCandles, _maxCandles);
    yield currentCandles;
  }
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
