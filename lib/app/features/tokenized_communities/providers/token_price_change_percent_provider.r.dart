// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_olhcv_candles_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_change_calculator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_price_change_percent_provider.r.g.dart';

// Provider that calculates the price change percentage.
// For now uses 1h candles to calculate 24h change for realtime updates.
// Can be easily adjusted later if needed.
@riverpod
double tokenPriceChangePercent(
  Ref ref,
  String externalAddress,
) {
  final candlesAsync = ref.watch(
    tokenOhlcvCandlesProvider(externalAddress, '1h'),
  );

  return candlesAsync.when(
    data: (candles) {
      final percent = calculatePriceChangePercentFromNow(
        candles,
        const Duration(hours: 24),
      );
      // Round to 2 decimals so tiny float noise doesn't flip the color to red.
      return (percent * 100).round() / 100;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}
