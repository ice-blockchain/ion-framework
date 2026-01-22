// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_change_calculator.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

void main() {
  group('calculatePriceChangePercentFromNow', () {
    OhlcvCandle createCandle({
      required DateTime date,
      required double close,
      double open = 0,
      double high = 0,
      double low = 0,
      double volume = 0,
    }) {
      return OhlcvCandle(
        timestamp: date.microsecondsSinceEpoch,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      );
    }

    group('edge cases', () {
      test('returns 0.0 when candles list is empty', () {
        final result = calculatePriceChangePercentFromNow(
          [],
          const Duration(hours: 24),
        );
        expect(result, 0.0);
      });

      test('returns 0.0 when past price is zero', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 0),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 0.0);
      });

      test('returns 0.0 when current price is zero but past price is not', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 0),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, -100.0);
      });

      test('handles single candle', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 12)), close: 1),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 0.0);
      });

      test('handles unsorted candles correctly', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 12)), close: 1.5),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 100.0);
      });
    });

    group('core cases', () {
      test('calculates correctly when exact match exists at target time', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 24)), close: 1.5),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, closeTo(33.333, 0.1));
      });

      test('uses latest candle <= target time when no exact match', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 26)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1.2),
          createCandle(date: now.subtract(const Duration(hours: 23)), close: 1.8),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, closeTo(66.666, 0.1));
      });

      test('falls back to oldest candle when all candles are newer than target', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 12)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 6)), close: 1.5),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 100.0);
      });

      test('handles negative price change correctly', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 2),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 1),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, -50.0);
      });

      test('handles large price increase', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 0.1),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 10),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 9900.0);
      });

      test('handles very small price changes', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 1.001),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, closeTo(0.1, 0.0001));
      });
    });

    group('time-based scenarios', () {
      test('handles candles with gaps in data', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 48)), close: 1),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 100.0);
      });

      test('handles zero duration', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 1),
          createCandle(date: now.subtract(const Duration(minutes: 30)), close: 2),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          Duration.zero,
        );
        expect(result, 0.0);
      });
    });

    group('bad cases and error scenarios', () {
      test('handles very old candles (all before target)', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(days: 10)), close: 0.5),
          createCandle(date: now.subtract(const Duration(days: 5)), close: 1),
          createCandle(date: now.subtract(const Duration(days: 2)), close: 1.5),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 0.0);
      });
    });

    group('precision and calculation accuracy', () {
      test('maintains precision for small decimal values', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 0.0001),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 0.0002),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 100.0);
      });

      test('handles very large price values', () {
        final now = DateTime.now();
        final candles = [
          createCandle(date: now.subtract(const Duration(hours: 25)), close: 1000000),
          createCandle(date: now.subtract(const Duration(hours: 1)), close: 2000000),
        ];

        final result = calculatePriceChangePercentFromNow(
          candles,
          const Duration(hours: 24),
        );
        expect(result, 100.0);
      });
    });
  });
}
