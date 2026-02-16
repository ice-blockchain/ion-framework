// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_candles_normalizer.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_processed_data_provider.r.g.dart';

// Processed chart data containing candles ready for display.
class ChartProcessedData {
  const ChartProcessedData({
    required this.candlesToShow,
    required this.isEmpty,
  });

  final List<ChartCandle> candlesToShow;
  final bool isEmpty;
}

@riverpod
ChartProcessedData chartProcessedData(
  Ref ref, {
  required List<OhlcvCandle> candles,
  required Decimal baselineClose,
  required double baselineMarketCap,
  required ChartTimeRange selectedRange,
  required DateTime tokenCreatedAt,
}) {
  final chartCandles = _mapOhlcvToChartCandles(candles);
  final isEmpty = chartCandles.isEmpty;

  final normalizedCandles =
      chartCandles.isNotEmpty ? normalizeCandles(chartCandles, selectedRange) : chartCandles;

  final candlesToShow = isEmpty
      ? _buildFlatCandles(
          baselineClose,
          baselineMarketCap,
          selectedRange,
          tokenCreatedAt,
        )
      // Edge case: If normalization still returns 1 candle (typically when candle is at "now"),
      // expand to 2 candles for proper visualization
      : normalizedCandles.length == 1
          ? _expandSingleCandleToFlatLine(
              normalizedCandles.first,
              tokenCreatedAt,
            )
          : normalizedCandles;

  return ChartProcessedData(
    candlesToShow: candlesToShow,
    isEmpty: isEmpty,
  );
}

// Maps OHLCV candles from analytics package to ChartCandle format.
List<ChartCandle> _mapOhlcvToChartCandles(List<OhlcvCandle> source) {
  return source
      .map(
        (candle) => ChartCandle(
          open: candle.open,
          high: candle.high,
          low: candle.low,
          close: candle.close,
          marketCap: candle.marketCap,
          price: Decimal.parse(candle.close.toString()),
          date: candle.timestamp.toDateTime,
        ),
      )
      .toList();
}

// Builds flat candles for empty state (all candles at same price).
// Creates candles respecting token creation, with max 35 candles.
// For young tokens: starts from creation. For old tokens: starts from 35 intervals back.
List<ChartCandle> _buildFlatCandles(
  Decimal baselineClose,
  double baselineMarketCap,
  ChartTimeRange selectedRange,
  DateTime tokenCreatedAt,
) {
  final now = DateTime.now();
  final interval = selectedRange.duration;
  const maxCount = 35;
  final closeValue = double.tryParse(baselineClose.toString()) ?? 0;
  final marketCapValue = baselineMarketCap;

  // Start from the later of: tokenCreatedAt OR (now - maxCount * interval)
  final earliestAllowed = now.subtract(interval * maxCount);
  final startDate = tokenCreatedAt.isAfter(earliestAllowed) ? tokenCreatedAt : earliestAllowed;

  final candles = <ChartCandle>[];

  // Fill from startDate to "now"
  var fillDate = startDate;
  while (!fillDate.isAfter(now)) {
    candles.add(
      ChartCandle(
        open: closeValue,
        high: closeValue,
        low: closeValue,
        close: closeValue,
        marketCap: marketCapValue,
        price: baselineClose,
        date: fillDate,
      ),
    );
    fillDate = fillDate.add(interval);
  }

  // Ensure minimum 2 candles (for very young tokens where startDate ≈ now)
  if (candles.length < 2) {
    if (candles.length == 1) {
      // Add candle at "now" if different from first
      if (candles.first.date != now) {
        candles.add(
          ChartCandle(
            open: closeValue,
            high: closeValue,
            low: closeValue,
            close: closeValue,
            marketCap: marketCapValue,
            price: baselineClose,
            date: now,
          ),
        );
      } else {
        // First candle is at "now", add one at startDate
        candles.insert(
          0,
          ChartCandle(
            open: closeValue,
            high: closeValue,
            low: closeValue,
            close: closeValue,
            marketCap: marketCapValue,
            price: baselineClose,
            date: startDate,
          ),
        );
      }
    } else {
      // No candles (Edge case, added for safety)
      candles
        ..add(
          ChartCandle(
            open: closeValue,
            high: closeValue,
            low: closeValue,
            close: closeValue,
            marketCap: marketCapValue,
            price: baselineClose,
            date: startDate,
          ),
        )
        ..add(
          ChartCandle(
            open: closeValue,
            high: closeValue,
            low: closeValue,
            close: closeValue,
            marketCap: marketCapValue,
            price: baselineClose,
            date: now,
          ),
        );
    }
  }

  return candles;
}

// Expands a single candle into a flat line for better visualization.
// Creates 2 candles: [candle, now] to ensure we don't go before token creation.
List<ChartCandle> _expandSingleCandleToFlatLine(
  ChartCandle candle,
  DateTime tokenCreatedAt,
) {
  final now = DateTime.now();
  final close = candle.close;
  final marketCap = candle.marketCap;
  final priceDecimal = Decimal.parse(close.toStringAsFixed(4));

  // If candle is already at "now" (or very close), expand backward to tokenCreatedAt
  // Otherwise expand forward to "now"
  final candleIsAtNow = now.difference(candle.date).abs() < const Duration(seconds: 1);

  if (candleIsAtNow) {
    // Candle is at "now", expand backward to tokenCreatedAt
    return [
      ChartCandle(
        open: close,
        high: close,
        low: close,
        close: close,
        marketCap: marketCap,
        price: priceDecimal,
        date: tokenCreatedAt,
      ),
      candle,
    ];
  }

  // Normal case: expand forward to "now"
  return [
    candle,
    ChartCandle(
      open: close,
      high: close,
      low: close,
      close: close,
      marketCap: marketCap,
      price: priceDecimal,
      date: now,
    ),
  ];
}
