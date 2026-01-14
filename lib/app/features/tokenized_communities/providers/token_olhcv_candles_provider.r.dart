// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_olhcv_candles_provider.r.g.dart';

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

  yield initialCandles;

  // 2. Subscribe to realtime updates
  final subscription = await client.communityTokens.subscribeToOhlcvCandles(
    ionConnectAddress: externalAddress,
    interval: interval,
  );

  ref.onDispose(subscription.close);

  final currentCandles = List<OhlcvCandle>.from(initialCandles);
  const maxCandles = 50;

  // 3. Process realtime updates
  await for (final batch in subscription.stream) {
    if (batch.isEmpty) {
      yield currentCandles;
      continue;
    }

    for (final candle in batch) {
      final existingIndex = currentCandles.indexWhere(
        (existing) => existing.timestamp == candle.timestamp,
      );

      if (existingIndex >= 0) {
        currentCandles[existingIndex] = candle;
      } else {
        currentCandles.add(candle);
      }
    }

    // Remove oldest candles if exceeding max
    if (currentCandles.length > maxCandles) {
      final amountToRemove = currentCandles.length - maxCandles;
      currentCandles.removeRange(0, amountToRemove);
    }

    yield currentCandles;
  }
}
