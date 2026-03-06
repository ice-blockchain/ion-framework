// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion_ads/src/config/theme_data.dart';

class AdChoicesContainer extends StatelessWidget {
  const AdChoicesContainer({super.key, this.backGroundColor});

  final Color? backGroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      padding: const EdgeInsets.only(left: 3, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: context.colors.onPrimaryAccent,
        borderRadius: BorderRadius.circular(5.54),
      ),
      child: SvgPicture.asset(
        'assets/images/ad_choices.svg',
        package: 'ion_ads',
      ),
    );
  }
}
