// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class FollowButton extends StatelessWidget {
  const FollowButton({
    required this.onPressed,
    required this.isFollowing,
    // required this.style,
    // required this.styleWhenFollowing,
    required this.decoration,
    required this.decorationWhenFollowing,
    this.visibility = FollowButtonVisibility.always,
    this.followLabel,
    super.key,
  });

  final VoidCallback onPressed;

  final bool isFollowing;

  final String? followLabel;

  final FollowButtonVisibility visibility;

  final FollowButtonDecoration decoration;

  final FollowButtonDecoration decorationWhenFollowing;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = isFollowing ? decorationWhenFollowing : decoration;

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      padding: effectiveDecoration.contentPadding,
      decoration: effectiveDecoration,
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            (isFollowing ? Assets.svg.iconSearchFollowers : Assets.svg.iconSearchFollow).icon(
              color: effectiveDecoration.foregroundColor,
              size: 16.0.s,
            ),
            if (effectiveDecoration.showLabel) ...[
              SizedBox(width: 3.0.s),
              Text(
                isFollowing
                    ? context.i18n.button_following
                    : followLabel ?? context.i18n.button_follow,
                style: context.theme.appTextThemes.caption.copyWith(
                  color: isFollowing
                      ? context.theme.appColors.primaryAccent
                      : context.theme.appColors.secondaryBackground,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class FollowButtonDecoration extends BoxDecoration {
  final Color foregroundColor;
  final EdgeInsetsGeometry contentPadding;
  final bool showLabel;

  FollowButtonDecoration({
    required this.foregroundColor,
    EdgeInsetsGeometry? contentPadding,
    this.showLabel = true,
    super.color,
    super.border,
    super.borderRadius,
  }) : this.contentPadding =
            contentPadding ?? EdgeInsets.symmetric(horizontal: 14.0.s, vertical: 4.0.s);
}

class FollowButtonStyle extends ButtonStyle {
  FollowButtonStyle({
    this.showLabel = true,
    EdgeInsetsGeometry? padding,
    OutlinedBorder? shape,
    Color? backgroundColor,
    Color? foregroundColor,
    this.type = ButtonType.primary,
  }) : super(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          foregroundColor: WidgetStateProperty.all(foregroundColor),
          padding: WidgetStateProperty.all(padding ?? EdgeInsets.symmetric(horizontal: 15.0.s)),
          shape: WidgetStateProperty.all(
            shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.s)),
          ),
        );

  final bool showLabel;

  final ButtonType type;
}

enum FollowButtonVisibility {
  always,
  keepUntilRestart,
}
