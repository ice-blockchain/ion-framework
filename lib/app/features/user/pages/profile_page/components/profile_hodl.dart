// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileHODL extends StatelessWidget {
  const ProfileHODL({
    required this.time,
    super.key,
  });

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          Assets.svg.iconCreatecoinHold,
          width: 14.0.s,
          height: 14.0.s,
        ),
        SizedBox(width: 4.0.s),
        Text(
          // Show compact HODL like "1h23m"
          context.i18n.hodl_for(
            DateTime.now().difference(time).isNegative ? '0m' : formatCompactHodlSince(time),
          ),
          style: context.theme.appTextThemes.caption2.copyWith(
            color: context.theme.appColors.secondaryBackground,
          ),
        ),
      ],
    );
  }
}
