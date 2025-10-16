// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.type = ButtonType.primary,
    this.style = const ButtonStyle(),
    this.tintColor,
    this.borderColor,
    this.borderRadius,
    this.backgroundColor,
    this.size = 56.0,
    this.disabled = false,
    this.fixedSize,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.textOverflow = TextOverflow.ellipsis,
    this.spacing = 6.0,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonStyle style;
  final Color? tintColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double size;
  final bool disabled;
  final Size? fixedSize;

  final TextStyle? textStyle;
  final TextAlign textAlign;
  final TextOverflow textOverflow;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Button.icon(
          type: type,
          onPressed: onPressed,
          icon: icon,
          style: style,
          tintColor: tintColor,
          borderColor: borderColor,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          size: size,
          disabled: disabled,
          fixedSize: fixedSize,
        ),
        SizedBox(height: spacing.s),
        Text(
          label,
          style: textStyle ?? context.theme.appTextThemes.caption2,
          textAlign: textAlign,
          overflow: textOverflow,
        ),
      ],
    );
  }
}
