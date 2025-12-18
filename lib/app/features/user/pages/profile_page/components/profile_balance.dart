// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/components/dividers/gradient_vertical_divider.dart';
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
      decoration: BoxDecoration(
        color: context.theme.appColors.backgroundBlue,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 44.0.s, vertical: 16.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  Assets.svg.iconMemeCoins,
                ),
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
            const Spacer(),
            const GradientVerticalDivider(),
            const Spacer(),
            Expanded(
              child: Row(
                children: [
                  SvgPicture.asset(
                    Assets.svg.iconCreatecoinDollar,
                  ),
                  SizedBox(
                    width: 4.0.s,
                  ),
                  Text(
                    market_data_formatters.formatPrice(amount, symbol: ''),
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
