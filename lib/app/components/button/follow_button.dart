// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class FollowButton extends HookWidget {
  const FollowButton({
    required this.onPressed,
    required this.isFollowing,
    required this.decoration,
    required this.decorationWhenFollowing,
    this.visibility = FollowButtonVisibility.always,
    this.followLabel,
    super.key,
  });

  final Future<void> Function()? onPressed;

  final bool isFollowing;

  final String? followLabel;

  final FollowButtonVisibility visibility;

  final FollowButtonDecoration decoration;

  final FollowButtonDecoration decorationWhenFollowing;

  @override
  Widget build(BuildContext context) {
    final isKeptVisible = useState<bool>(false);
    final isDisabled = useState<bool>(false);

    if (visibility == FollowButtonVisibility.keepUntilRefresh) {
      if (isFollowing && !isKeptVisible.value) {
        return const SizedBox.shrink();
      }
    }

    final effectiveDecoration = isFollowing ? decorationWhenFollowing : decoration;

    Future<void> handlePressed() async {
      if (visibility == FollowButtonVisibility.keepUntilRefresh) {
        isKeptVisible.value = true;
      }
      isDisabled.value = true;
      await onPressed?.call();
      isDisabled.value = false;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: effectiveDecoration.contentPadding,
      decoration: effectiveDecoration,
      alignment: Alignment.center,
      child: TextButton(
        onPressed: isDisabled.value ? null : handlePressed,
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
            ],
          ],
        ),
      ),
    );
  }
}

class FollowButtonDecoration extends BoxDecoration {
  FollowButtonDecoration({
    required this.foregroundColor,
    EdgeInsetsGeometry? contentPadding,
    this.showLabel = true,
    super.color,
    super.border,
    super.borderRadius,
  }) : contentPadding = contentPadding ?? EdgeInsets.symmetric(horizontal: 14.0.s, vertical: 4.0.s);

  final Color foregroundColor;
  final EdgeInsetsGeometry contentPadding;
  final bool showLabel;
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
  keepUntilRefresh,
}
