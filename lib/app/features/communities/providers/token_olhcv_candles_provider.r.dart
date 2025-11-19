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
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToOhlcvCandles(
    ionConnectAddress: ionConnectAddress,
    interval: interval,
  );

  try {
    yield* subscription.stream;
  } finally {
    await subscription.close();
  }
}
