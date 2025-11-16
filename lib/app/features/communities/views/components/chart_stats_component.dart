// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class ChartStatsComponent extends StatelessWidget {
  const ChartStatsComponent({
    required this.selectedTimeframe,
    required this.timeframes,
    required this.volumeText,
    required this.buysText,
    required this.sellsText,
    required this.netBuyText,
    required this.onTimeframeTap,
    super.key,
  });

  final int selectedTimeframe;
  final List<TimeframeChange> timeframes;
  final String volumeText;
  final String buysText;
  final String sellsText;
  final String netBuyText;
  final ValueChanged<int> onTimeframeTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final i18n = context.i18n;

    return ColoredBox(
      color: colors.secondaryBackground,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.primaryBackground,
                borderRadius: BorderRadius.circular(16.0.s),
              ),
              padding: EdgeInsets.symmetric(vertical: 4.0.s),
              child: Row(
                children: [
                  for (var i = 0; i < timeframes.length; i++)
                    Expanded(
                      child: _TimeframeChip(
                        data: timeframes[i],
                        isSelected: selectedTimeframe == i,
                        onTap: () => onTimeframeTap(i),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12.0.s),
            // KPI row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _KpiColumn(
                  title: i18n.chart_stats_volume,
                  value: volumeText,
                  valueColor: colors.primaryText,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                _KpiColumn(
                  title: i18n.chart_stats_buys,
                  value: buysText,
                  valueColor: colors.primaryText,
                ),
                _KpiColumn(
                  title: i18n.chart_stats_sells,
                  value: sellsText,
                  valueColor: colors.lossRed,
                ),
                _KpiColumn(
                  title: i18n.chart_stats_net_buy,
                  value: netBuyText,
                  valueColor: colors.success,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  const _TimeframeChip({
    required this.data,
    this.onTap,
    this.isSelected = false,
  });

  final TimeframeChange data;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    final changeColor = data.percent >= 0 ? colors.success : colors.lossRed;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSelected ? 10.0.s : 4.0.s,
          horizontal: 4.0.s,
        ),
        margin: EdgeInsets.all(4.0.s),
        decoration: BoxDecoration(
          color: isSelected ? colors.onPrimaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 12.0.s : 10.0.s),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: texts.caption2.copyWith(color: colors.quaternaryText),
            ),
            SizedBox(height: 4.0.s),
            Text(
              _formatPercent(data.percent),
              textAlign: TextAlign.center,
              style: texts.body.copyWith(color: changeColor, height: 18 / texts.body.fontSize!),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiColumn extends StatelessWidget {
  const _KpiColumn({
    required this.title,
    required this.value,
    required this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String title;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return SizedBox(
      width: 72.0.s,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            title,
            style: texts.caption2.copyWith(color: colors.quaternaryText),
          ),
          SizedBox(height: 4.0.s),
          Text(
            value,
            style: texts.body.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class TimeframeChange {
  const TimeframeChange({
    required this.label,
    required this.percent,
  });

  final String label; // e.g. '5m'
  final double percent; // e.g. -0.55
}

String _formatPercent(double p) {
  final sign = p >= 0 ? '+' : '';
  return '$sign${p.toStringAsFixed(2)}%';
}
