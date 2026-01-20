// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

/// A price label container widget used in token list items.
///
/// This component provides a consistent styling for displaying price/amount
/// information in token-related list items, such as holdings and creator tokens.
class TokenPriceLabel extends StatelessWidget {
  const TokenPriceLabel({
    required this.text,
    this.textStyle,
    this.textColor,
    this.height,
    super.key,
  });

  /// The text to display (e.g., formatted price or amount)
  final String text;

  /// Optional custom text style. If not provided, uses caption2 with appropriate color.
  final TextStyle? textStyle;

  /// Optional text color. If not provided, uses onPrimaryAccent.
  final Color? textColor;

  /// Optional fixed height. If not provided, uses intrinsic height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ??
        context.theme.appTextThemes.caption2.copyWith(
          color: textColor ?? context.theme.appColors.onPrimaryAccent,
          height: height == null ? 16 / context.theme.appTextThemes.caption2.fontSize! : null,
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryAccent,
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      height: height,
      child: Center(
        child: Text(
          text,
          style: effectiveTextStyle,
        ),
      ),
    );
  }
}
