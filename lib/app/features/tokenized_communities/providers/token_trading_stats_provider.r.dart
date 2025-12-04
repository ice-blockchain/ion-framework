// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_trading_stats_provider.r.g.dart';

@riverpod
Stream<Map<String, TradingStats>> tokenTradingStats(
  Ref ref,
  String masterPubkey,
) async* {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToTradingStats(
    ionConnectAddress: masterPubkey,
  );

  try {
    yield* subscription.stream;
  } finally {
    await subscription.close();
  }
}
