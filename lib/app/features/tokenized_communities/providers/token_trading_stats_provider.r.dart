// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_trading_stats_provider.r.g.dart';

@riverpod
Stream<Map<String, TradingStats>> tokenTradingStats(
  Ref ref,
  String externalAddress,
) async* {
  final client = await ref.watch(ionTokenAnalyticsClientProvider.future);
  final subscription = await client.communityTokens.subscribeToTradingStats(
    ionConnectAddress: externalAddress,
  );

  ref.onDispose(subscription.close);

  final currentStats = <String, TradingStats>{};

  try {
    await for (final statsMap in subscription.stream) {
      // Update state: merge new stats into current
      currentStats.addAll(statsMap);

      yield currentStats;
    }
  } catch (e) {
    // Yield the last known state one more time before stream terminates
    // This ensures Riverpod keeps it as AsyncData instead of transitioning to AsyncError
    if (currentStats.isNotEmpty) {
      yield currentStats;
    }
  }
}
