// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

enum ProfileChartType {
  raising,
  falling,
}

class ProfileChart extends StatelessWidget {
  const ProfileChart({
    required this.amount,
    super.key,
  });

  final double amount;

  @override
  Widget build(BuildContext context) {
    final type =
        amount > 0 ? ProfileChartType.raising : ProfileChartType.falling;
    final color = switch (type) {
      ProfileChartType.raising => context.theme.appColors.profitGreen,
      ProfileChartType.falling => context.theme.appColors.lossRed,
    };

    final symbol = switch (type) {
      ProfileChartType.raising => r'+$',
      ProfileChartType.falling => r'-$',
    };

    return Container(
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0.s),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconChartLine,
              width: 14.0.s,
              height: 14.0.s,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.0.s),
            Text(
              formatToCurrency(amount, symbol),
              style: context.theme.appTextThemes.body2.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
