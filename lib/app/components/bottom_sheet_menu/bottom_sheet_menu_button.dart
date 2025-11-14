// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shadow/svg_shadow.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class BottomSheetMenuButton extends StatelessWidget {
  const BottomSheetMenuButton({
    required this.menuBuilder,
    this.iconColor,
    this.isAccentTheme = false,
    this.padding,
    this.iconSize,
    this.showShadow = false,
    super.key,
  });

  final Widget Function(BuildContext context) menuBuilder;
  final Color? iconColor;
  final bool isAccentTheme;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isAccentTheme
            ? context.theme.appColors.onPrimaryAccent
            : context.theme.appColors.onTertiaryBackground);

    final icon = Assets.svg.iconMorePopup.icon(
      color: effectiveIconColor,
      size: iconSize,
    );

    return GestureDetector(
      onTap: () {
        showSimpleBottomSheet<void>(
          context: context,
          child: menuBuilder(context),
        );
      },
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: showShadow ? SvgShadow(child: icon) : icon,
      ),
    );
  }
}
