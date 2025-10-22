// SPDX-License-Identifier: ice License 1.0

// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/generated/assets.gen.dart';

export 'variants/text_icon_button.dart';

part 'variants/button_compact.dart';
part 'variants/button_dropdown.dart';
part 'variants/button_icon.dart';
part 'variants/button_menu.dart';

enum ButtonType {
  primary,
  secondary,
  outlined,
  disabled,
  menuInactive,
  menuActive,
  dropdown,
}

class Button extends StatelessWidget {
  Button({
    required this.onPressed,
    super.key,
    this.trailingIcon,
    this.leadingIcon,
    this.label,
    this.style = const ButtonStyle(),
    this.mainAxisSize = MainAxisSize.min,
    this.type = ButtonType.primary,
    this.disabled = false,
    this.tintColor,
    this.borderColor,
    this.borderRadius,
    this.backgroundColor,
    this.minimumSize,
    this.labelFlex = 1,
    double? leadingIconOffset,
    double? trailingIconOffset,
  })  : leadingIconOffset = leadingIconOffset ?? 8.0.s,
        trailingIconOffset = trailingIconOffset ?? 8.0.s;

  factory Button.icon({
    required VoidCallback? onPressed,
    required Widget icon,
    Key? key,
    ButtonType type,
    ButtonStyle style,
    Color? tintColor,
    Color? borderColor,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    double size,
    bool disabled,
    Size? fixedSize,
  }) = _ButtonWithIcon;

  factory Button.compact({
    required VoidCallback onPressed,
    Key? key,
    Widget? trailingIcon,
    Widget? leadingIcon,
    Widget? label,
    ButtonStyle style,
    MainAxisSize mainAxisSize,
    ButtonType type,
    bool disabled,
    Color? tintColor,
    Color? backgroundColor,
    Size? minimumSize,
    double? leadingIconOffset,
  }) = _ButtonCompact;

  factory Button.menu({
    required VoidCallback onPressed,
    Key? key,
    Widget? trailingIcon,
    Widget? leadingIcon,
    Widget? label,
    ButtonStyle style,
    MainAxisSize mainAxisSize,
    Color? borderColor,
    Color? backgroundColor,
    bool disabled,
    bool active,
  }) = _ButtonMenu;

  factory Button.dropdown({
    required VoidCallback onPressed,
    Key? key,
    Widget? leadingIcon,
    Widget? label,
    ButtonStyle style,
    Color? borderColor,
    Color? backgroundColor,
    double? leadingIconOffset,
    double? trailingIconOffset,
    EdgeInsetsGeometry? padding,
    bool useDefaultBorderRadius,
    bool useDefaultPaddings,
    bool disabled,
    bool opened,
    bool showClearButton,
    VoidCallback? onClearTap,
  }) = _ButtonDropdown;

  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final Widget? label;
  final int labelFlex;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Size? minimumSize;
  final Color? tintColor;
  final ButtonStyle style;
  final MainAxisSize mainAxisSize;
  final ButtonType type;
  final bool disabled;
  final double leadingIconOffset;
  final double trailingIconOffset;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: type == ButtonType.disabled || disabled ? null : onPressed,
      style: style.merge(
        OutlinedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(16.0.s)),
          ),
          minimumSize: minimumSize ?? Size(56.0.s, 56.0.s),
          padding: EdgeInsets.symmetric(horizontal: 16.0.s),
          backgroundColor: _getBackgroundColor(context, type),
          side: BorderSide(
            color: _getBorderColor(context, type),
          ),
        ),
      ),
      child: IconTheme(
        data: IconThemeData(color: _getIconTintColor(context, type)),
        child: DefaultTextStyle(
          overflow: TextOverflow.ellipsis,
          style: context.theme.appTextThemes.body.copyWith(color: _getLabelColor(context, type)),
          child: Row(
            mainAxisSize: mainAxisSize,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) leadingIcon!,
              if (label != null)
                Flexible(
                  flex: labelFlex,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: leadingIcon == null ? 0 : leadingIconOffset,
                      end: trailingIcon == null ? 0 : trailingIconOffset,
                    ),
                    child: label,
                  ),
                ),
              if (trailingIcon != null) trailingIcon!,
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context, ButtonType type) {
    return backgroundColor ??
        switch (type) {
          ButtonType.primary => context.theme.appColors.primaryAccent,
          ButtonType.secondary => context.theme.appColors.tertiaryBackground,
          ButtonType.outlined => Colors.transparent,
          ButtonType.disabled => context.theme.appColors.sheetLine,
          ButtonType.menuInactive => context.theme.appColors.tertiaryBackground,
          ButtonType.menuActive => context.theme.appColors.secondaryBackground,
          ButtonType.dropdown => context.theme.appColors.tertiaryBackground,
        };
  }

  Color _getBorderColor(BuildContext context, ButtonType type) {
    return borderColor ??
        tintColor ??
        switch (type) {
          ButtonType.primary => context.theme.appColors.onPrimaryAccent,
          ButtonType.secondary => context.theme.appColors.tertiaryBackground,
          ButtonType.outlined => context.theme.appColors.strokeElements,
          ButtonType.disabled => context.theme.appColors.sheetLine,
          ButtonType.menuInactive => context.theme.appColors.onTertiaryFill,
          ButtonType.menuActive => context.theme.appColors.primaryAccent,
          ButtonType.dropdown => context.theme.appColors.onTertiaryFill,
        };
  }

  Color _getLabelColor(BuildContext context, ButtonType type) {
    return tintColor ??
        switch (type) {
          ButtonType.primary => context.theme.appColors.onPrimaryAccent,
          ButtonType.secondary => context.theme.appColors.primaryText,
          ButtonType.outlined => context.theme.appColors.secondaryText,
          ButtonType.disabled => context.theme.appColors.onPrimaryAccent,
          ButtonType.menuInactive => context.theme.appColors.tertiaryText,
          ButtonType.menuActive => context.theme.appColors.primaryText,
          ButtonType.dropdown => context.theme.appColors.primaryText,
        };
  }

  Color _getIconTintColor(BuildContext context, ButtonType type) {
    return tintColor ??
        switch (type) {
          ButtonType.primary => context.theme.appColors.onPrimaryAccent,
          ButtonType.secondary => context.theme.appColors.primaryAccent,
          ButtonType.outlined => context.theme.appColors.secondaryText,
          ButtonType.disabled => context.theme.appColors.onPrimaryAccent,
          ButtonType.menuInactive => context.theme.appColors.tertiaryText,
          ButtonType.menuActive => context.theme.appColors.primaryAccent,
          ButtonType.dropdown => context.theme.appColors.primaryText,
        };
  }
}

class ButtonIconFrame extends StatelessWidget {
  const ButtonIconFrame({
    required this.icon,
    super.key,
    this.color,
    this.border,
    this.containerSize,
    this.borderRadius,
  });

  final Color? color;
  final Widget icon;
  final Border? border;

  final double? containerSize;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final size = containerSize ?? 32.0.s;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(9.0.s),
        border: border,
      ),
      child: icon,
    );
  }
}
