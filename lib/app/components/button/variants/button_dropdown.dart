// SPDX-License-Identifier: ice License 1.0

part of '../button.dart';

class _ButtonDropdown extends Button {
  _ButtonDropdown({
    required super.onPressed,
    super.key,
    super.leadingIcon,
    super.label,
    super.disabled,
    super.backgroundColor,
    super.borderColor,
    double? leadingIconOffset,
    double? trailingIconOffset,
    bool opened = false,
    ButtonStyle style = const ButtonStyle(),
    bool useDefaultBorderRadius = false,
    bool useDefaultPaddings = false,
    EdgeInsetsGeometry? padding,
    bool showClearButton = false,
    VoidCallback? onClearTap,
  }) : super(
          type: ButtonType.dropdown,
          style: style.merge(
            OutlinedButton.styleFrom(
              shape: useDefaultBorderRadius == true
                  ? null
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0.s)),
                    ),
              minimumSize: Size.square(40.0.s),
              padding: padding ??
                  (useDefaultPaddings == true
                      ? null
                      : leadingIcon != null
                          ? EdgeInsetsDirectional.only(
                              start: leadingIconOffset ?? 6.0.s,
                              end: trailingIconOffset ?? 10.0.s,
                            )
                          : EdgeInsets.symmetric(horizontal: 14.0.s)),
            ),
          ),
          leadingIconOffset: leadingIconOffset ?? 10.0.s,
          trailingIcon: Row(
            children: [
              (opened ? Assets.svg.iconArrowUp : Assets.svg.iconArrowDown).icon(size: 12.0.s),
              if (showClearButton)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onClearTap?.call(),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: 8.0.s, top: 4.0.s, bottom: 4.0.s),
                    child: Assets.svg.iconSheetClose.icon(size: 16.0.s),
                  ),
                ),
            ],
          ),
          trailingIconOffset: trailingIconOffset ?? 8.0.s,
        );
}
