// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/components/dividers/gradient_vertical_divider.dart';
import 'package:ion/app/components/shapes/bottom_notch_rect_border.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/utils/formatters.dart'
    as market_data_formatters;
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileBalance extends StatelessWidget {
  const ProfileBalance({
    required this.height,
    required this.coins,
    required this.amount,
    super.key,
  });

  final double height;
  final double coins;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: ShapeDecoration(
        color: context.theme.appColors.backgroundBlue,
        shape: BottomNotchRectBorder(),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.s, vertical: 16.0.s),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.svg.iconMemeCoins.icon(size: 16.s),
                  SizedBox(
                    width: 4.0.s,
                  ),
                  Text(
                    coins >= 1 ? formatCount(coins.toInt()) : coins.toString(),
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.primaryBackground,
                    ),
                  ),
                ],
              ),
            ),
            const GradientVerticalDivider(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.svg.iconCreatecoinDollar.icon(size: 16.s),
                  SizedBox(
                    width: 1.0.s,
                  ),
                  Text(
                    market_data_formatters.formatPriceWithSubscript(amount, symbol: ''),
                    style: context.theme.appTextThemes.body2.copyWith(
                      color: context.theme.appColors.primaryBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
