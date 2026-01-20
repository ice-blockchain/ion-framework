// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';

// Normalizes candles by filling gaps based on selectedRange interval.
// Example: [10:00, 15:00] with 1h interval → [10:00, 11:00, 12:00, 13:00, 14:00, 15:00]
// Also fills gap from last candle to "now" (works for both single and multiple candles)
List<ChartCandle> normalizeCandles(
  List<ChartCandle> candles,
  ChartTimeRange selectedRange,
) {
  if (candles.isEmpty) return candles;

  // Sort by date to ensure correct order
  final sorted = List<ChartCandle>.from(candles)..sort((a, b) => a.date.compareTo(b.date));

  final interval = selectedRange.duration;
  final normalized = <ChartCandle>[];

  for (var i = 0; i < sorted.length; i++) {
    normalized.add(sorted[i]);

    // Check gap before next candle
    if (i < sorted.length - 1) {
      final current = sorted[i];
      final next = sorted[i + 1];
      final gap = next.date.difference(current.date);

      // Fill gap if it's larger than interval
      if (gap > interval) {
        var fillDate = current.date.add(interval);
        while (fillDate.isBefore(next.date)) {
          // Forward-fill: use previous candle's close price
          final fillPrice = Decimal.parse(current.close.toStringAsFixed(4));
          normalized.add(
            ChartCandle(
              open: current.close,
              high: current.close,
              low: current.close,
              close: current.close,
              price: fillPrice,
              date: fillDate,
            ),
          );
          fillDate = fillDate.add(interval);
        }
      }
    }
  }

  // Fill gap from last candle to "now"
  if (normalized.isNotEmpty) {
    final lastCandle = normalized.last;
    final now = DateTime.now();

    var fillDate = lastCandle.date.add(interval);
    while (!fillDate.isAfter(now)) {
      normalized.add(
        ChartCandle(
          open: lastCandle.close,
          high: lastCandle.close,
          low: lastCandle.close,
          close: lastCandle.close,
          price: Decimal.parse(lastCandle.close.toStringAsFixed(4)),
          date: fillDate,
        ),
      );
      fillDate = fillDate.add(interval);
    }
  }

  return normalized;
}
