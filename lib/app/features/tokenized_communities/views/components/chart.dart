// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/chart_processed_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_olhcv_candles_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart';
import 'package:ion/app/features/tokenized_communities/utils/price_label_formatter.dart';
import 'package:ion/app/features/tokenized_communities/views/components/token_area_line_chart.dart';
import 'package:ion/generated/assets.gen.dart';

class Chart extends HookConsumerWidget {
  const Chart({
    required this.externalAddress,
    required this.price,
    required this.label,
    super.key,
  });

  final String externalAddress;
  final Decimal price;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAtOfToken =
        ref.watch(tokenMarketInfoProvider(externalAddress).select((t) => t.valueOrNull?.createdAt));

    if (createdAtOfToken == null) {
      return const SizedBox.shrink();
    }

    final selectedRange = useState(ChartTimeRangeExtension.getRangeForCreatedAt(createdAtOfToken));

    final candlesAsync = ref.watch(
      tokenOhlcvCandlesProvider(
        externalAddress,
        selectedRange.value.intervalString,
      ),
    );

    final chartDisplayData = ref.watch(
      chartProcessedDataProvider(
        candles: candlesAsync.valueOrNull ?? const [],
        price: price,
        selectedRange: selectedRange.value,
      ),
    );

    return candlesAsync.when(
      data: (_) {
        return _ChartContent(
          price: price,
          label: label,
          changePercent: chartDisplayData.changePercent,
          candles: chartDisplayData.candlesToShow,
          isLoading: false,
          selectedRange: selectedRange.value,
          onRangeChanged: (range) => selectedRange.value = range,
        );
      },
      error: (error, stackTrace) {
        return _ChartContent(
          price: price,
          label: label,
          changePercent: 0,
          candles: chartDisplayData.candlesToShow,
          isLoading: false,
          selectedRange: selectedRange.value,
          onRangeChanged: (range) => selectedRange.value = range,
        );
      },
      loading: () {
        return _ChartContent(
          price: price,
          label: label,
          changePercent: 0,
          candles: demoCandles,
          isLoading: true,
          selectedRange: selectedRange.value,
          onRangeChanged: null,
        );
      },
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.price,
    required this.label,
    required this.changePercent,
    required this.candles,
    required this.isLoading,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final Decimal price;
  final String label;
  final double changePercent;
  final List<ChartCandle> candles;
  final bool isLoading;
  final ChartTimeRange selectedRange;
  final ValueChanged<ChartTimeRange>? onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return ColoredBox(
      color: colors.secondaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.0.s),
          const _ChartHeader(),
          SizedBox(height: 4.0.s),
          _ValueAndChange(
            price: price,
            label: label,
            changePercent: changePercent,
          ),
          SizedBox(height: 10.0.s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.7,
                child: TokenAreaLineChart(
                  candles: candles,
                  isLoading: isLoading,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.0.s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
            child: _RangeSelector(
              selected: selectedRange,
              onChanged: onRangeChanged,
            ),
          ),
          SizedBox(height: 12.0.s),
        ],
      ),
    );
  }
}

String _formatPrice(Decimal p) => p.toStringAsFixed(4);

class _ChartHeader extends StatelessWidget {
  const _ChartHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    final titleRow = Row(
      children: [
        Assets.svg.iconCreatecoinProfit.icon(
          size: 18.0.s,
          color: colors.onTertiaryBackground,
        ),
        SizedBox(width: 6.0.s),
        Text(
          i18n.chart_label,
          style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: titleRow,
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
              formatPercent(changePercent),
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
                  style: texts.caption5.copyWith(fontSize: 6.5.s, color: colors.tertiaryText),
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

extension ChartTimeRangeExtension on ChartTimeRange {
  String get label => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '1d',
      };

  String get intervalString => switch (this) {
        ChartTimeRange.m1 => '1m',
        ChartTimeRange.m3 => '3m',
        ChartTimeRange.m5 => '5m',
        ChartTimeRange.m15 => '15m',
        ChartTimeRange.m30 => '30m',
        ChartTimeRange.h1 => '1h',
        ChartTimeRange.d1 => '24h',
      };

  Duration get duration => switch (this) {
        ChartTimeRange.m1 => const Duration(minutes: 1),
        ChartTimeRange.m3 => const Duration(minutes: 3),
        ChartTimeRange.m5 => const Duration(minutes: 5),
        ChartTimeRange.m15 => const Duration(minutes: 15),
        ChartTimeRange.m30 => const Duration(minutes: 30),
        ChartTimeRange.h1 => const Duration(hours: 1),
        ChartTimeRange.d1 => const Duration(days: 1),
      };

  static ChartTimeRange getRangeForCreatedAt(String createdAt) {
    final now = DateTime.now();
    final diff = now.difference(DateTime.parse(createdAt));
    if (diff.inHours > 8) {
      if (diff.inDays > 8) {
        return ChartTimeRange.d1;
      }
      return ChartTimeRange.h1;
    }
    return ChartTimeRange.m15;
  }
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
