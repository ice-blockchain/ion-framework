// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

enum ProfileChartType {
  raising,
  falling,
  idle,
}

extension ProfileChartTypeColor on ProfileChartType {
  Color getColor(BuildContext context) {
    switch (this) {
      case ProfileChartType.raising:
        return context.theme.appColors.success;
      case ProfileChartType.falling:
        return context.theme.appColors.raspberry;
      case ProfileChartType.idle:
        return context.theme.appColors.success;
    }
  }
}

class ProfileChart extends StatelessWidget {
  const ProfileChart({
    required this.amount,
    super.key,
  });

  final double amount;

  @override
  Widget build(BuildContext context) {
    final type = amount > 0
        ? ProfileChartType.raising
        : amount < 0
            ? ProfileChartType.falling
            : ProfileChartType.idle;

    final symbol = switch (type) {
      ProfileChartType.raising => r'+$',
      ProfileChartType.falling => r'-$',
      ProfileChartType.idle => r'$',
    };

    return Container(
      decoration: ShapeDecoration(
        color: type.getColor(context),
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
                context.theme.appColors.primaryBackground,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.0.s),
            Text(
              formatToCurrency(amount.abs(), symbol),
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
