// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TagButton extends StatelessWidget {
  const TagButton({
    required this.onPressed,
    required this.label,
    this.leadingIcon,
    super.key,
  });

  final VoidCallback onPressed;

  final String label;

  final String? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      leadingIcon: leadingIcon?.icon(
        color: context.theme.appColors.primaryAccent,
        size: 16.s,
      ),
      leadingIconOffset: 2.0.s,
      trailingIcon: Assets.svg.iconArrowRight.icon(
        color: context.theme.appColors.primaryAccent,
        size: 14.s,
      ),
      trailingIconOffset: 2.0.s,
      type: ButtonType.outlined,
      tintColor: context.theme.appColors.primaryBackground,
      backgroundColor: context.theme.appColors.primaryBackground,
      label: Text(
        label,
        style: context.theme.appTextThemes.caption2.copyWith(
          color: context.theme.appColors.primaryAccent,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
        minimumSize: Size.zero,
      ),
    );
  }
}
