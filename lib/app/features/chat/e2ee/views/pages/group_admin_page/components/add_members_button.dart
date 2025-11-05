// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class AddMembersButton extends StatelessWidget {
  const AddMembersButton({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 8.0.s),
        decoration: ShapeDecoration(
          color: context.theme.appColors.tertiaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0.s),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.svg.iconButtonInvite.icon(
                  size: 24.0.s,
                  color: context.theme.appColors.primaryAccent,
                ),
                SizedBox(width: 6.0.s),
                Text(
                  context.i18n.group_add_members_button,
                  style: context.theme.appTextThemes.subtitle3.copyWith(
                    color: context.theme.appColors.primaryAccent,
                  ),
                ),
              ],
            ),
            Assets.svg.iconArrowRight.icon(
              size: 24.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
          ],
        ),
      ),
    );
  }
}
