// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_olhcv_candles_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_change_calculator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_24h_change_candles_provider.r.g.dart';

// This provider calculates the 24-hour price change percentage.
// Uses the existing tokenOhlcvCandlesProvider with 1h interval to get realtime updates.
// The calculation finds the price at DateTime.now() - 24 hours (or older if not available)
// and compares it with the latest price.
@riverpod
double token24hChangePercent(
  Ref ref,
  String externalAddress,
) {
  final candlesAsync = ref.watch(
    tokenOhlcvCandlesProvider(externalAddress, '1h'),
  );

  return candlesAsync.when(
    data: calculate24hPriceChangePercent,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}
