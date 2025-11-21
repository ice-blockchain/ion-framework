// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class BoostInfoRow extends StatelessWidget {
  const BoostInfoRow({
    required this.label,
    required this.value,
    required this.onInfoTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.primaryText,
              ),
            ),
            SizedBox(width: 8.0.s),
            GestureDetector(
              onTap: onInfoTap,
              child: Assets.svg.iconBlockInformation.icon(
                size: 16.0.s,
                color: context.theme.appColors.quaternaryText,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: context.theme.appTextThemes.body2.copyWith(
            color: context.theme.appColors.primaryText,
          ),
        ),
      ],
    );
  }
}
