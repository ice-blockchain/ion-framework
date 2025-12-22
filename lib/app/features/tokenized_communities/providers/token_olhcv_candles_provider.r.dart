// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_olhcv_candles_provider.r.g.dart';

@riverpod
Stream<List<OhlcvCandle>> tokenOhlcvCandles(
  Ref ref,
  String ionConnectAddress,
  String interval,
) async* {
  // Loading state: while connection is being established
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToOhlcvCandles(
    ionConnectAddress: ionConnectAddress,
    interval: interval,
  );

  // Connection established - yield empty list to transition from loading to data state
  // This allows widget to show "no data" state instead of loading forever
  final currentCandles = <OhlcvCandle>[];
  yield currentCandles;

  try {
    await for (final candle in subscription.stream) {
      currentCandles.add(candle);
      yield currentCandles;
    }
  } finally {
    await subscription.close();
  }
}
