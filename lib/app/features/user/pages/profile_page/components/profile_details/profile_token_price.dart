// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/num.dart';

class ProfileTokenPrice extends StatelessWidget {
  const ProfileTokenPrice({
    required this.amount,
    super.key,
  });

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: ShapeDecoration(
        color: context.theme.appColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0.s),
        ),
      ),
      child: Text(
        formatToCurrency(amount),
        textAlign: TextAlign.center,
        style: context.theme.appTextThemes.caption3.copyWith(
          color: context.theme.appColors.primaryText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
