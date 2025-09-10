// SPDX-License-Identifier: ice License 1.0

part of '../button.dart';

class _ButtonWithIcon extends Button {
  _ButtonWithIcon({
    required super.onPressed,
    required Widget icon,
    super.key,
    super.type,
    super.tintColor,
    super.borderColor,
    super.borderRadius,
    super.backgroundColor,
    super.borderWidth,
    super.disabled,
    ButtonStyle style = const ButtonStyle(),
    double? size,
    Size? fixedSize,
  }) : super(
          leadingIcon: icon,
          style: style.merge(
            OutlinedButton.styleFrom(
              fixedSize: fixedSize ?? Size.square(size ?? 56.0.s),
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              backgroundColor: backgroundColor,
            ),
          ),
        );
}
