// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';

class ProfileAction extends StatelessWidget {
  const ProfileAction({
    required this.onPressed,
    required this.assetName,
    this.isAccent = false,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String assetName;
  final VoidCallback onPressed;
  final bool isAccent;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    if (profileMode == ProfileMode.dark) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 16.0.s),
          child: assetName.icon(
            size: 24.0.s,
            color: colors.secondaryBackground,
          ),
        ),
      );
    }

    return Button.icon(
      size: 36.0.s,
      fixedSize: Size(36.0.s, 24.0.s),
      borderRadius: BorderRadius.circular(20.0.s),
      borderColor: colors.onTertiaryFill,
      backgroundColor: colors.tertiaryBackground,
      tintColor: colors.primaryText,
      icon: assetName.icon(
        size: 16.0.s,
        color: isAccent ? colors.primaryAccent : colors.primaryText,
      ),
      onPressed: onPressed,
    );
  }
}
