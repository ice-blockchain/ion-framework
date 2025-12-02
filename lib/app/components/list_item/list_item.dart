// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/generated/assets.gen.dart';

part './variants/list_item_dapp.dart';
part './variants/list_item_popup.dart';
part './variants/list_item_text_with_icon.dart';
part './variants/list_item_user.dart';

class ListItem extends StatelessWidget {
  ListItem({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? leadingPadding,
    EdgeInsetsGeometry? trailingPadding,
    BoxConstraints? constraints,
    CrossAxisAlignment? crossAxisAlignment,
    bool? switchTitleStyles,
    this.secondary,
    this.isSelected,
    this.backgroundColor,
    this.onTap,
  })  : crossAxisAlignment = crossAxisAlignment ?? defaultCrossAxisAlignment,
        borderRadius = borderRadius ?? defaultBorderRadius,
        contentPadding = contentPadding ?? defaultContentPadding,
        leadingPadding = leadingPadding ?? defaultLeadingPadding,
        trailingPadding = trailingPadding ?? defaultTrailingPadding,
        switchTitleStyles = switchTitleStyles ?? false,
        constraints = constraints ?? defaultConstraints;

  factory ListItem.user({
    required Widget title,
    required Widget subtitle,
    String? pubkey,
    Key? key,
    Widget? leading,
    Widget? trailing,
    BoxBorder? border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? leadingPadding,
    EdgeInsetsGeometry? trailingPadding,
    BoxConstraints? constraints,
    Color? backgroundColor,
    VoidCallback? onTap,
    bool verifiedBadge,
    bool iceBadge,
    bool isSelected,
    double? avatarSize,
    Widget? avatarWidget,
  }) = _ListItemUser;

  factory ListItem.dapp({
    required Widget title,
    required Widget subtitle,
    Key? key,
    Widget? leading,
    Widget? trailing,
    BoxBorder? border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? leadingPadding,
    EdgeInsetsGeometry? trailingPadding,
    BoxConstraints? constraints,
    Color? backgroundColor,
    VoidCallback? onTap,
    String? profilePicture,
    Widget? profilePictureWidget,
    bool verifiedBadge,
    bool isSelected,
  }) = _ListItemDApp;

  factory ListItem.popup({
    required Widget title,
    required Widget subtitle,
    Key? key,
    Widget? leading,
    Widget? trailing,
  }) = _ListItemPopup;

  factory ListItem.text({
    required Widget title,
    required String value,
    Key? key,
    Color? backgroundColor,
  }) = _ListItemTextWithIcon;

  factory ListItem.textWithIcon({
    required Widget title,
    String? value,
    Widget? icon,
    Widget? secondary,
    Key? key,
    Color? backgroundColor,
  }) = _ListItemTextWithIcon;

  final Widget? leading;
  final Widget? title;
  final Widget? secondary;
  final Widget? subtitle;
  final bool switchTitleStyles;
  final Widget? trailing;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry leadingPadding;
  final EdgeInsetsGeometry trailingPadding;
  final CrossAxisAlignment? crossAxisAlignment;
  final BoxConstraints constraints;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool? isSelected;

  static BorderRadius get defaultBorderRadius => BorderRadius.all(Radius.circular(16.0.s));

  static EdgeInsets get defaultContentPadding =>
      EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s);

  static EdgeInsetsDirectional get defaultLeadingPadding => EdgeInsetsDirectional.only(
        end: 10.0.s,
      );

  static EdgeInsetsDirectional get defaultTrailingPadding => EdgeInsetsDirectional.only(
        start: 10.0.s,
      );

  static BoxConstraints get defaultConstraints => BoxConstraints(minHeight: 60.0.s);

  static CrossAxisAlignment get defaultCrossAxisAlignment => CrossAxisAlignment.center;

  static double get defaultAvatarSize => 30.0.s;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      alignment: Alignment.center,
      constraints: constraints,
      padding: contentPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: crossAxisAlignment ?? defaultCrossAxisAlignment,
            children: [
              if (leading != null)
                if (leadingPadding != EdgeInsets.zero)
                  Padding(padding: leadingPadding, child: leading)
                else
                  leading!,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: switchTitleStyles
                            ? _getDefaultSubtitleStyle(context)
                            : _getDefaultTitleStyle(context),
                        overflow: TextOverflow.ellipsis,
                        child: title!,
                      ),
                    if (subtitle != null)
                      DefaultTextStyle(
                        style: switchTitleStyles
                            ? _getDefaultTitleStyle(context)
                            : _getDefaultSubtitleStyle(context),
                        overflow: TextOverflow.ellipsis,
                        child: subtitle!,
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                if (trailingPadding != EdgeInsets.zero)
                  Padding(padding: trailingPadding, child: trailing)
                else
                  trailing!,
            ],
          ),
          if (secondary != null)
            DefaultTextStyle(
              style: switchTitleStyles
                  ? _getDefaultSubtitleStyle(context)
                  : _getDefaultTitleStyle(context),
              child: secondary!,
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          border: border,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    return (isSelected ?? false)
        ? context.theme.appColors.primaryAccent
        : backgroundColor ?? context.theme.appColors.tertiaryBackground;
  }

  TextStyle _getDefaultTitleStyle(BuildContext context) {
    return context.theme.appTextThemes.body.copyWith(
      color: (isSelected ?? false)
          ? context.theme.appColors.onPrimaryAccent
          : context.theme.appColors.primaryText,
    );
  }

  TextStyle _getDefaultSubtitleStyle(BuildContext context) {
    return context.theme.appTextThemes.caption3.copyWith(
      color: (isSelected ?? false)
          ? context.theme.appColors.onPrimaryAccent
          : context.theme.appColors.secondaryText,
    );
  }
}
