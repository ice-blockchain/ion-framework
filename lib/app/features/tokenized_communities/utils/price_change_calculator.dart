// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

/// Calculates the price change percentage from candles over a given duration.
///
/// Returns the percentage change from the price X time ago to the latest price.
/// Returns 0.0 if:
/// - Candles list is empty
/// - No candle found from the target time ago
/// - Previous price is zero (to avoid division by zero)
///
/// Formula: ((current_price - past_price) / past_price) * 100
///
/// Example:
/// - Latest candle close: $2.00
/// - Candle 1 hour ago close: $1.00
/// - Result: ((2.00 - 1.00) / 1.00) * 100 = 100.0%
double calculatePriceChangePercent(
  List<OhlcvCandle> candles,
  Duration duration,
) {
  if (candles.isEmpty) return 0;

  final sortedCandles = List<OhlcvCandle>.from(candles)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final latestCandle = sortedCandles.last;
  final currentPrice = latestCandle.close;
  final targetTimestamp = latestCandle.timestamp - duration.inMicroseconds;
  OhlcvCandle? pastCandle;
  for (var i = sortedCandles.length - 1; i >= 0; i--) {
    if (sortedCandles[i].timestamp <= targetTimestamp) {
      pastCandle = sortedCandles[i];
      break;
    }
  }

  // Edge cases: no past candle found or past price is zero
  if (pastCandle == null || pastCandle.close == 0) return 0;

  final pastPrice = pastCandle.close;

  // Calculate percentage change: ((current - past) / past) * 100
  return ((currentPrice - pastPrice) / pastPrice) * 100;
}
