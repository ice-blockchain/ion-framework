// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

/// Calculates the price change percentage from a specific duration ago to now.
///
/// Uses absolute time (DateTime.now()) to find the price at DateTime.now() - duration
/// (or the latest candle <= that time) and compares it with the latest available price.
///
/// Returns 0.0 if candles are empty, no past price is found, or past price is zero.
double calculatePriceChangePercentFromNow(
  List<OhlcvCandle> candles,
  Duration duration,
) {
  if (candles.isEmpty) return 0;

  final sortedCandles = List<OhlcvCandle>.from(candles)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Get the latest price (most recent candle, closest to DateTime.now())
  final latestCandle = sortedCandles.last;
  final currentPrice = latestCandle.close;

  // Find the price at DateTime.now() - duration, or the latest candle <= that time
  final now = DateTime.now();
  final targetTime = now.subtract(duration);
  final targetTimestamp = targetTime.microsecondsSinceEpoch;

  OhlcvCandle? pastCandle;
  // Iterate from oldest to newest to find the latest candle that is still <= target time
  // This gives us the price at exactly duration ago if it exists, or the latest candle <= that time
  for (var i = 0; i < sortedCandles.length; i++) {
    final candle = sortedCandles[i];
    if (candle.timestamp <= targetTimestamp) {
      pastCandle = candle;
      // Continue to find the latest candle that is still <= target time
    } else {
      // We've passed the target time, use the last candle we found
      break;
    }
  }

  // If no candle found at or before target time (all candles are newer),
  // use the oldest available candle as fallback
  pastCandle ??= sortedCandles.first;

  if (pastCandle.close == 0) return 0;

  final pastPrice = pastCandle.close;
  return ((currentPrice - pastPrice) / pastPrice) * 100;
}
