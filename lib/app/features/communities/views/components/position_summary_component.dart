// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/models/position_summary.dart';
import 'package:ion/app/features/communities/utils/position_formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class PositionSummaryComponent extends StatelessWidget {
  const PositionSummaryComponent({
    required this.summary,
    this.abbreviateSupply = defaultAbbreviate,
    this.formatUsd = defaultUsd,
    super.key,
  });

  final PositionSummary summary;
  final SupplyAbbreviator abbreviateSupply;
  final UsdFormatter formatUsd;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final i18n = context.i18n;

    final changePrefix = summary.changeAmountUsd >= 0 ? '+' : '';
    final changeColor = summary.changeAmountUsd >= 0 ? colors.success : colors.lossRed;

    return Semantics(
      label: i18n.common_information,
      child: Container(
        color: colors.secondaryBackground,
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _YourPosition(
              changeText:
                  '$changePrefix${formatUsd(summary.changeAmountUsd)} (${summary.changePercent.toStringAsFixed(2)}%)',
              changeColor: changeColor,
            ),
            _SupplyAndPrice(
              supplyText: abbreviateSupply(summary.circulatingSupply),
              priceText: NumberFormat('#,##0.##', 'en_US').format(summary.priceUsd),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourPosition extends StatelessWidget {
  const _YourPosition({required this.changeText, required this.changeColor});

  final String changeText;
  final Color changeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    final i18n = context.i18n;

    return Row(
      children: [
        // Icon container as in Figma: 52x52 visual
        Container(
          width: 52.0.s,
          height: 52.0.s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.onTertiaryFill,
          ),
          alignment: Alignment.center,
          child: Assets.svg.iconCreatecoinNewcoin
              .icon(size: 26.0.s, color: colors.onTertiaryBackground),
        ),
        SizedBox(width: 10.0.s),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.common_information, // i18n: label text; if a dedicated key is added, replace
              style: texts.subtitle3.copyWith(color: colors.onTertiaryBackground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: i18n.common_information,
            ),
            SizedBox(height: 6.0.s),
            Row(
              children: [
                Assets.svg.iconChartCaremoji.icon(size: 14.0.s, color: colors.onTertiaryBackground),
                SizedBox(width: 4.0.s),
                Text(
                  changeText,
                  style: texts.body2.copyWith(color: changeColor),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SupplyAndPrice extends StatelessWidget {
  const _SupplyAndPrice({required this.supplyText, required this.priceText});

  final String supplyText;
  final String priceText;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Assets.svg.iconTabsCoins.icon(size: 16.0.s, color: colors.onTertiaryBackground),
            SizedBox(width: 4.0.s),
            Text(
              supplyText,
              style: texts.body2.copyWith(color: colors.onTertiaryBackground),
            ),
          ],
        ),
        SizedBox(height: 6.0.s),
        Row(
          children: [
            // Reusing receive icon for dollar – replace if a proper asset is available later
            Assets.svg.iconButtonReceive.icon(size: 16.0.s, color: colors.onTertiaryBackground),
            SizedBox(width: 4.0.s),
            Text(
              priceText,
              style: texts.body2.copyWith(color: colors.onTertiaryBackground),
            ),
          ],
        ),
      ],
    );
  }
}
