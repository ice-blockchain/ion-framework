// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/utils/price_label_formatter.dart';
import 'package:ion/app/features/communities/views/components/token_area_line_chart.dart';
import 'package:ion/generated/assets.gen.dart';

class ChartComponent extends StatelessWidget {
  const ChartComponent({
    required this.price,
    required this.label,
    required this.changePercent,
    required this.candles,
    required this.selectedRange,
    required this.onRangeChanged,
    super.key,
  });

  final Decimal price;
  final String label;
  final double changePercent;
  final List<ChartCandle> candles;
  final ChartTimeRange selectedRange;
  final ValueChanged<ChartTimeRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Container(
      color: colors.secondaryBackground,
      padding: EdgeInsets.symmetric(vertical: 16.0.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(),
          SizedBox(height: 4.0.s),
          _ValueAndChange(
            price: price,
            label: label,
            changePercent: changePercent,
          ),
          SizedBox(height: 10.0.s),
          Center(
            child: AspectRatio(
              aspectRatio: 1.7,
              child: TokenAreaLineChart(candles: candles),
            ),
          ),
          SizedBox(height: 4.0.s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
            child: _RangeSelector(
              selected: selectedRange,
              onChanged: onRangeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPrice(Decimal p) => p.toStringAsFixed(4);

class _ChartHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Row(
        children: [
          Assets.svg.iconCreatecoinNewcoin.icon(
            size: 18.0.s,
            color: colors.onTertiaryBackground,
          ),
          SizedBox(width: 6.0.s),
          Text(
            i18n.chart_label,
            style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
          ),
        ],
      ),
    );
  }
}

class _ValueAndChange extends StatelessWidget {
  const _ValueAndChange({
    required this.price,
    required this.label,
    required this.changePercent,
  });

  final Decimal price;
  final String label;
  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${_formatPrice(price)} $label',
              overflow: TextOverflow.ellipsis,
              style: texts.subtitle.copyWith(color: colors.primaryText),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
            decoration: BoxDecoration(
              color: changePercent >= 0 ? colors.success : colors.lossRed,
              borderRadius: BorderRadius.circular(6.0.s),
            ),
            child: Text(
              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: texts.caption2.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPriceLabel extends StatelessWidget {
  const ChartPriceLabel({required this.value, super.key});
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    final parts = PriceLabelFormatter.format(value);

    if (parts.fullText != null) {
      return Text(
        parts.fullText!,
        style: texts.caption5.copyWith(color: colors.tertiaryText),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: texts.caption5.copyWith(color: colors.tertiaryText),
        children: [
          TextSpan(text: parts.prefix ?? ''),
          if (parts.subscript != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Transform.translate(
                offset: Offset(0, 2.0.s),
                child: Text(
                  parts.subscript!,
                  style: texts.caption5.copyWith(fontSize: 6.5.s),
                ),
              ),
            ),
          TextSpan(text: parts.trailing ?? ''),
        ],
      ),
    );
  }
}

enum ChartTimeRange { m1, m3, m5, m15, m30, h1, d1 }

extension on ChartTimeRange {
  String get label => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '1d',
      };
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, this.onChanged});
  final ChartTimeRange selected;
  final ValueChanged<ChartTimeRange>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    Widget chip(ChartTimeRange range) {
      final isSelected = range == selected;
      return GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(range),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsetsDirectional.only(end: 8.0.s),
          padding: EdgeInsets.symmetric(horizontal: 10.0.s, vertical: 3.0.s),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryAccent : colors.primaryBackground,
            borderRadius: BorderRadius.circular(8.0.s),
          ),
          child: Text(
            range.label,
            style: texts.caption2.copyWith(
              color: isSelected ? colors.onPrimaryAccent : colors.secondaryText,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                chip(ChartTimeRange.m1),
                chip(ChartTimeRange.m3),
                chip(ChartTimeRange.m5),
                chip(ChartTimeRange.m15),
                chip(ChartTimeRange.m30),
                chip(ChartTimeRange.h1),
                chip(ChartTimeRange.d1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChartCandle {
  const ChartCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.price,
    required this.date,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final Decimal price;
  final DateTime date;
}

// Simple demo data to render something if no candles are provided.
final demoCandles = _generateDemoCandles();

List<ChartCandle> _generateDemoCandles() {
  final now = DateTime.now();

  // Generate a deterministic series spanning multiple candles per day
  // so we can verify axis labeling when there are many points between dates.
  const numDays = 8;
  const candlesPerDay = 4; // multiple candles between dates
  const totalCandles = numDays * candlesPerDay;

  const base = 0.00033;
  const waveAmplitude = 0.000015; // slow sinusoidal trend
  const microWave = 0.000004; // small oscillation to vary highs/lows

  var previousClose = base;
  final candles = <ChartCandle>[];

  for (var i = 0; i < totalCandles; i++) {
    final progress = i / totalCandles;
    final trend = math.sin(progress * math.pi * 2) * waveAmplitude;
    final wobble = math.sin(i * 1.7) * microWave;

    // Target close value around the base with smooth oscillations.
    final targetClose = (base + trend + wobble).clamp(0.0002, 0.001);

    final open = previousClose;
    final close = targetClose;
    final high = math.max(open, close) + microWave.abs();
    final low = math.min(open, close) - microWave.abs();

    // Group candles by day; time-of-day is not rendered in the axis label.
    final dayIndex = i ~/ candlesPerDay;
    final date =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: numDays - 1 - dayIndex));

    candles.add(
      ChartCandle(
        open: open,
        high: high,
        low: low,
        close: close,
        price: Decimal.parse(close.toStringAsFixed(4)),
        date: date,
      ),
    );

    previousClose = close;
  }

  return candles;
}
