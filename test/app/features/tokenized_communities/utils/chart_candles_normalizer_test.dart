// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_candles_normalizer.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';

void main() {
  group('normalizeCandles', () {
    final baseDate = DateTime(2024, 1, 1, 10);

    const interval15min = Duration(minutes: 15);
    const interval1h = Duration(hours: 1);
    const interval2h = Duration(hours: 2);
    const interval24h = Duration(hours: 24);

    final interval1h15min = interval1h + interval15min;
    final interval1h45min = interval2h - interval15min;
    final interval2h30min = interval2h + const Duration(minutes: 30);
    final interval23h45min = interval24h - interval15min;

    const price1 = 1.0;
    const price2 = 2.0;
    const price3 = 3.0;

    void expectCandle(
      ChartCandle candle, {
      required DateTime date,
      required double close,
      double? open,
      double? high,
      double? low,
      Decimal? price,
    }) {
      expect(candle.date, date);
      expect(candle.close, close);
      if (open != null) expect(candle.open, open);
      if (high != null) expect(candle.high, high);
      if (low != null) expect(candle.low, low);
      if (price != null) expect(candle.price, price);
    }

    void expectCandleAtDate(
      List<ChartCandle> candles,
      DateTime date, {
      required double close,
    }) {
      final candle = candles.firstWhere((c) => c.date == date);
      expect(candle.close, close);
    }

    ChartCandle createCandle({
      required DateTime date,
      double price = 1.0,
      double? open,
      double? high,
      double? low,
      double? close,
    }) {
      final closePrice = close ?? price;
      return ChartCandle(
        open: open ?? price,
        high: high ?? price,
        low: low ?? price,
        close: closePrice,
        price: Decimal.parse(closePrice.toStringAsFixed(4)),
        date: date,
      );
    }

    group('edge cases', () {
      test('returns empty list when input is empty', () {
        final result = normalizeCandles([], ChartTimeRange.m15);
        expect(result, isEmpty);
      });

      test('fills single candle from past to now', () {
        // Create a candle from 1 hour ago
        final pastDate = DateTime.now().subtract(const Duration(hours: 1));
        final candle = createCandle(date: pastDate);
        final result = normalizeCandles([candle], ChartTimeRange.m15);

        // Should have more than 1 candle (original + filled ones)
        expect(result.length, greaterThan(1));
        // First candle should be the original
        expectCandle(result[0], date: pastDate, close: price1);
        // Last candle should be close to "now" (within one interval)
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
        // All filled candles should use the original close price
        for (var i = 1; i < result.length; i++) {
          expect(result[i].close, price1);
        }
      });
    });

    group('no gaps', () {
      test('returns two candles with fill to now when no gap exists', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval15min), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        // Should have at least 2 candles (original) + filled to now
        expect(result.length, greaterThanOrEqualTo(2));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price2);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });

      test('does not fill gap when gap equals interval but fills to now', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(interval15min)),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        // Should have at least 2 candles (original) + filled to now
        expect(result.length, greaterThanOrEqualTo(2));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price1);
      });

      test('does not fill gap when gap is smaller than interval but fills to now', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(const Duration(minutes: 10))),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        // Should have at least 2 candles (original) + filled to now
        expect(result.length, greaterThanOrEqualTo(2));
      });
    });

    group('single gap filling', () {
      test('fills single gap correctly and fills to now', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval2h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        // Should have at least 9 candles (2 original + 7 filled between) + filled to now
        expect(result.length, greaterThanOrEqualTo(9));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval1h45min), close: price1);
        // Check that the second original candle exists
        expectCandleAtDate(result, baseDate.add(interval2h), close: price2);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });

      test('handles very large gaps correctly and fills to now', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(interval24h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        // Should have at least 97 candles (2 original + 95 filled between) + filled to now
        expect(result.length, greaterThanOrEqualTo(97));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval2h30min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval23h45min), close: price1);
        // Check that the second original candle exists
        expectCandleAtDate(result, baseDate.add(interval24h), close: price2);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });
    });

    group('multiple gaps', () {
      test('fills multiple gaps correctly and fills to now', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval1h), price: price2),
          createCandle(date: baseDate.add(interval2h30min), price: price3),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        // Should have at least 11 candles (3 original + 8 filled between) + filled to now
        expect(result.length, greaterThanOrEqualTo(11));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval1h), close: price2);
        expectCandleAtDate(result, baseDate.add(interval1h15min), close: price2);
        // Check that the last original candle exists
        expectCandleAtDate(result, baseDate.add(interval2h30min), close: price3);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });
    });

    group('data integrity', () {
      test('sorts unsorted input before normalizing and fills to now', () {
        final candles = [
          createCandle(date: baseDate.add(interval15min), price: price2),
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        // Should have at least 2 candles (original) + filled to now
        expect(result.length, greaterThanOrEqualTo(2));
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price2);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });

      test('preserves original candle properties', () {
        const openValue = 1.5;
        const highValue = 2.0;
        const lowValue = 1.0;
        const closeValue = 1.8;
        final originalCandle = createCandle(
          date: baseDate,
          open: openValue,
          high: highValue,
          low: lowValue,
          close: closeValue,
        );
        final candles = [
          originalCandle,
          createCandle(date: baseDate.add(interval1h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expectCandle(
          result[0],
          date: baseDate,
          close: closeValue,
          open: openValue,
          high: highValue,
          low: lowValue,
          price: Decimal.parse('1.8'),
        );
      });

      test('filled candles use close price from previous candle', () {
        const fillPrice = 1.2345;
        final candles = [
          createCandle(
            date: baseDate,
            open: price1,
            high: 1.5,
            low: 0.9,
            close: fillPrice,
          ),
          createCandle(date: baseDate.add(interval1h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expectCandle(
          result[1],
          date: baseDate.add(interval15min),
          close: fillPrice,
          open: fillPrice,
          high: fillPrice,
          low: fillPrice,
          price: Decimal.parse('1.2345'),
        );
      });
    });

    group('different intervals', () {
      test('works with different time ranges and fills to now', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(const Duration(hours: 3))),
        ];

        final result1h = normalizeCandles(candles, ChartTimeRange.h1);
        // Should have at least 4 candles (2 original + 2 filled between) + filled to now
        expect(result1h.length, greaterThanOrEqualTo(4));

        final result15m = normalizeCandles(candles, ChartTimeRange.m15);
        // Should have at least 13 candles (2 original + 11 filled between) + filled to now
        expect(result15m.length, greaterThanOrEqualTo(13));
      });
    });

    group('fill to now', () {
      test('fills gap from last candle to now for multiple candles', () {
        // Create candles ending 2 hours ago
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: twoHoursAgo.subtract(interval1h), price: price1),
          createCandle(date: twoHoursAgo, price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        // Should have original candles + filled ones to "now"
        expect(result.length, greaterThan(2));
        // First candle should be original
        expectCandle(result[0], date: twoHoursAgo.subtract(interval1h), close: price1);
        // Second candle should be original
        final secondCandle = result.firstWhere((c) => c.date == twoHoursAgo);
        expect(secondCandle.close, price2);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval15min));
      });

      test('does not fill if last candle is very recent', () {
        // Create a candle just 5 minutes ago (less than 15min interval)
        final recentDate = DateTime.now().subtract(const Duration(minutes: 5));
        final candle = createCandle(date: recentDate);
        final result = normalizeCandles([candle], ChartTimeRange.m15);

        // Should only have the original candle (gap < interval)
        expect(result.length, 1);
        expectCandle(result[0], date: recentDate, close: price1);
      });

      test('fills single candle from yesterday to now', () {
        // Create a candle from yesterday
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        // ignore: avoid_redundant_argument_values
        final candle = createCandle(date: yesterday, price: price1);
        final result = normalizeCandles([candle], ChartTimeRange.h1);

        // Should have many candles (original + filled ones)
        expect(result.length, greaterThan(20)); // At least 24 hours worth
        // First candle should be original
        expectCandle(result[0], date: yesterday, close: price1);
        // Last candle should be close to "now"
        final lastCandle = result.last;
        final now = DateTime.now();
        final gapToNow = now.difference(lastCandle.date);
        expect(gapToNow, lessThan(interval1h));
      });
    });
  });
}
