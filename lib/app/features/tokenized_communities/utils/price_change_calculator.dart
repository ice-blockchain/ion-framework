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

  if (pastCandle == null || pastCandle.close == 0) return 0;

  final pastPrice = pastCandle.close;
  return ((currentPrice - pastPrice) / pastPrice) * 100;
}

/// Calculates the 24-hour price change percentage.
///
/// Finds the price at DateTime.now() - 24 hours (or the oldest available candle
/// if no exact match exists) and compares it with the latest price.
///
/// Returns 0.0 if candles are empty, no past price is found, or past price is zero.
double calculate24hPriceChangePercent(List<OhlcvCandle> candles) {
  if (candles.isEmpty) return 0;

  final sortedCandles = List<OhlcvCandle>.from(candles)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Get the latest price (most recent candle, closest to DateTime.now())
  final latestCandle = sortedCandles.last;
  final currentPrice = latestCandle.close;

  // Find the price at DateTime.now() - 24 hours, or the oldest candle <= that time
  final now = DateTime.now();
  final targetTime = now.subtract(const Duration(hours: 24));
  final targetTimestamp = targetTime.microsecondsSinceEpoch;

  OhlcvCandle? pastCandle;
  // Iterate from oldest to newest to find the latest candle that is still <= 24 hours ago
  // This gives us the price at exactly 24h ago if it exists, or the latest candle <= 24h ago
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

  // If no candle found at or before target time (all candles are newer than 24h),
  // use the oldest available candle as fallback
  pastCandle ??= sortedCandles.first;

  if (pastCandle.close == 0) return 0;

  final pastPrice = pastCandle.close;
  return ((currentPrice - pastPrice) / pastPrice) * 100;
}
