// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class OutlinedIcon extends StatelessWidget {
  const OutlinedIcon({required this.icon, this.size, super.key});
  final double? size;
  final Widget icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? 36.0.s,
      height: size ?? 36.0.s,
      padding: EdgeInsets.all(7.0.s),
      decoration: ShapeDecoration(
        color: context.theme.appColors.secondaryBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.0.s,
            color: context.theme.appColors.onTertiaryFill,
          ),
          borderRadius: BorderRadius.circular(10.0.s),
        ),
      ),
      child: icon,
    );
  }
}
