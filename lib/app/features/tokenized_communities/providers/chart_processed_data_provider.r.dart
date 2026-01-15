// SPDX-License-Identifier: ice License 1.0

import 'package:decimal/decimal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/tokenized_communities/utils/chart_candles_normalizer.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_change_calculator.dart';
import 'package:ion/app/features/tokenized_communities/views/components/chart.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_processed_data_provider.r.g.dart';

// Processed chart data containing candles ready for display and price change information.
class ChartProcessedData {
  const ChartProcessedData({
    required this.candlesToShow,
    required this.changePercent,
    required this.isEmpty,
  });

  final List<ChartCandle> candlesToShow;
  final double changePercent;
  final bool isEmpty;
}

@riverpod
ChartProcessedData chartProcessedData(
  Ref ref, {
  required List<OhlcvCandle> candles,
  required Decimal price,
  required ChartTimeRange selectedRange,
}) {
  final chartCandles = _mapOhlcvToChartCandles(candles);
  final isEmpty = chartCandles.isEmpty;

  final normalizedCandles =
      chartCandles.length > 1 ? normalizeCandles(chartCandles, selectedRange) : chartCandles;

  final candlesToShow = isEmpty
      ? _buildFlatCandles(price)
      : normalizedCandles.length == 1
          ? _expandSingleCandleToFlatLine(normalizedCandles.first, selectedRange)
          : normalizedCandles;

  final changePercent =
      isEmpty ? 0.0 : calculatePriceChangePercent(candles, selectedRange.duration);

  return ChartProcessedData(
    candlesToShow: candlesToShow,
    changePercent: changePercent,
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
          price: Decimal.parse(candle.close.toString()),
          date: candle.timestamp.toDateTime,
        ),
      )
      .toList();
}

// Builds flat candles for empty state (all candles at same price).
List<ChartCandle> _buildFlatCandles(Decimal price) {
  final now = DateTime.now();
  const count = 20;
  final value = double.tryParse(price.toString()) ?? 0;

  return List<ChartCandle>.generate(count, (index) {
    final date = now.subtract(Duration(minutes: (count - index) * 15));
    return ChartCandle(
      open: value,
      high: value,
      low: value,
      close: value,
      price: price,
      date: date,
    );
  });
}

// Expands a single candle into a flat line for better visualization.
List<ChartCandle> _expandSingleCandleToFlatLine(
  ChartCandle candle,
  ChartTimeRange range,
) {
  final timeSpan = range.duration;
  const count = 2;
  final price = candle.close;

  return List<ChartCandle>.generate(count, (index) {
    final progress = index / (count - 1);
    final date = candle.date.subtract(timeSpan * (1 - progress));

    return ChartCandle(
      open: price,
      high: price,
      low: price,
      close: price,
      price: Decimal.parse(price.toStringAsFixed(4)),
      date: date,
    );
  });
}
