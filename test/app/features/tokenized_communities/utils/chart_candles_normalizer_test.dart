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

      test('returns single candle unchanged', () {
        final candle = createCandle(date: baseDate);
        final result = normalizeCandles([candle], ChartTimeRange.m15);
        expect(result, [candle]);
      });
    });

    group('no gaps', () {
      test('returns two candles unchanged when no gap exists', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval15min), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        expect(result.length, 2);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price2);
      });

      test('does not fill gap when gap equals interval', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(interval15min)),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        expect(result.length, 2);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price1);
      });

      test('does not fill gap when gap is smaller than interval', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(const Duration(minutes: 10))),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);
        expect(result.length, 2);
      });
    });

    group('single gap filling', () {
      test('fills single gap correctly', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval2h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expect(result.length, 9);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval1h45min), close: price1);
        expectCandle(result[result.length - 1], date: baseDate.add(interval2h), close: price2);
      });

      test('handles very large gaps correctly', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(interval24h), price: price2),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expect(result.length, 97);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval2h30min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval23h45min), close: price1);
        expectCandle(result[result.length - 1], date: baseDate.add(interval24h), close: price2);
      });
    });

    group('multiple gaps', () {
      test('fills multiple gaps correctly', () {
        final candles = [
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
          createCandle(date: baseDate.add(interval1h), price: price2),
          createCandle(date: baseDate.add(interval2h30min), price: price3),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expect(result.length, 11);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandleAtDate(result, baseDate.add(interval15min), close: price1);
        expectCandleAtDate(result, baseDate.add(interval1h), close: price2);
        expectCandleAtDate(result, baseDate.add(interval1h15min), close: price2);
        expectCandle(result[result.length - 1], date: baseDate.add(interval2h30min), close: price3);
      });
    });

    group('data integrity', () {
      test('sorts unsorted input before normalizing', () {
        final candles = [
          createCandle(date: baseDate.add(interval15min), price: price2),
          // ignore: avoid_redundant_argument_values
          createCandle(date: baseDate, price: price1),
        ];

        final result = normalizeCandles(candles, ChartTimeRange.m15);

        expect(result.length, 2);
        expectCandle(result[0], date: baseDate, close: price1);
        expectCandle(result[1], date: baseDate.add(interval15min), close: price2);
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
      test('works with different time ranges', () {
        final candles = [
          createCandle(date: baseDate),
          createCandle(date: baseDate.add(const Duration(hours: 3))),
        ];

        final result1h = normalizeCandles(candles, ChartTimeRange.h1);
        expect(result1h.length, 4);

        final result15m = normalizeCandles(candles, ChartTimeRange.m15);
        expect(result15m.length, 13);
      });
    });
  });
}
