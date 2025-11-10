// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupRoleActionItem extends StatelessWidget {
  const GroupRoleActionItem({
    required this.title,
    required this.onTap,
    required this.iconAsset,
    this.iconColor,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final String iconAsset;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return ScreenSideOffset.small(
      child: ListItem(
        contentPadding: EdgeInsetsDirectional.only(
          start: ScreenSideOffset.defaultSmallMargin,
          end: 8.0.s,
        ),
        title: Text(
          title,
          style: textStyles.body,
        ),
        backgroundColor: colors.tertiaryBackground,
        onTap: onTap,
        leading: ButtonIconFrame(
          containerSize: 36.0.s,
          borderRadius: BorderRadius.circular(10.0.s),
          color: colors.onPrimaryAccent,
          icon: iconAsset.icon(
            size: 24.0.s,
            color: iconColor ?? colors.attentionRed,
          ),
          border: Border.fromBorderSide(
            BorderSide(color: colors.onTertiaryFill, width: 1.0.s),
          ),
        ),
        trailing: Padding(
          padding: EdgeInsets.all(8.0.s),
          child: Assets.svg.iconArrowRight.icon(
            color: colors.tertiaryText,
          ),
        ),
      ),
    );
  }
}
