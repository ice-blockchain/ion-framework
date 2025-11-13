// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class BottomSheetMenuButton extends StatelessWidget {
  const BottomSheetMenuButton({
    required this.menuBuilder,
    this.iconColor,
    this.isAccentTheme = false,
    this.padding,
    super.key,
  });

  final Widget Function(BuildContext context) menuBuilder;
  final Color? iconColor;
  final bool isAccentTheme;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isAccentTheme
            ? context.theme.appColors.onPrimaryAccent
            : context.theme.appColors.onTertiaryBackground);

    return GestureDetector(
      onTap: () {
        showSimpleBottomSheet<void>(
          context: context,
          child: menuBuilder(context),
        );
      },
      child: Padding(
        padding: padding ??
            EdgeInsetsGeometry.symmetric(
              horizontal: ScreenSideOffset.defaultSmallMargin,
              vertical: 5.0.s,
            ),
        child: Assets.svg.iconMorePopup.icon(
          color: effectiveIconColor,
        ),
      ),
    );
  }
}
