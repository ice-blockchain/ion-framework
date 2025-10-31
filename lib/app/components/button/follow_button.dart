// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/generated/assets.gen.dart';

class FollowButton extends HookWidget {
  const FollowButton({
    required this.onPressed,
    required this.following,
    this.decoration,
    this.decorationWhenFollowing,
    this.visibility = FollowButtonVisibility.always,
    this.followLabel,
    super.key,
  });

  final Future<void> Function()? onPressed;

  final bool following;

  final String? followLabel;

  final FollowButtonVisibility visibility;

  final FollowButtonDecoration? decoration;

  final FollowButtonDecoration? decorationWhenFollowing;

  @override
  Widget build(BuildContext context) {
    final isKeptVisible = useState<bool>(false);
    final isDisabled = useState<bool>(false);

    if (visibility == FollowButtonVisibility.keepUntilRefresh) {
      if (following && !isKeptVisible.value) {
        return const SizedBox.shrink();
      }
    }

    final effectiveDecoration = following
        ? (decorationWhenFollowing ??
            FollowButtonDecoration.defaultDecorationWhenFollowing(context))
        : (decoration ?? FollowButtonDecoration.defaultDecoration(context));

    Future<void> handlePressed() async {
      if (visibility == FollowButtonVisibility.keepUntilRefresh) {
        isKeptVisible.value = true;
      }
      isDisabled.value = true;
      try {
        await onPressed?.call();
      } catch (e, s) {
        Logger.error(e, stackTrace: s, message: 'Error following user');
      } finally {
        isDisabled.value = false;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: effectiveDecoration.contentPadding,
      decoration: effectiveDecoration,
      alignment: Alignment.center,
      curve: Curves.easeInOut,
      child: TextButton(
        onPressed: isDisabled.value ? null : handlePressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            (following ? Assets.svg.iconSearchFollowers : Assets.svg.iconSearchFollow).icon(
              color: effectiveDecoration.foregroundColor,
              size: 16.0.s,
            ),
            if (effectiveDecoration.showLabel) ...[
              SizedBox(width: 3.0.s),
              Text(
                following
                    ? context.i18n.button_following
                    : followLabel ?? context.i18n.button_follow,
                style: context.theme.appTextThemes.caption.copyWith(
                  color: following
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

  factory FollowButtonDecoration.defaultDecoration(BuildContext context) {
    return FollowButtonDecoration(
      foregroundColor: context.theme.appColors.onPrimaryAccent,
      color: context.theme.appColors.primaryAccent,
      borderRadius: BorderRadius.circular(16.0.s),
      border: Border.all(color: context.theme.appColors.primaryAccent),
    );
  }

  factory FollowButtonDecoration.defaultDecorationWhenFollowing(BuildContext context) {
    return FollowButtonDecoration(
      foregroundColor: context.theme.appColors.primaryAccent,
      color: context.theme.appColors.primaryAccent.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(16.0.s),
      border: Border.all(color: context.theme.appColors.primaryAccent),
    );
  }

  final Color foregroundColor;
  final EdgeInsetsGeometry contentPadding;
  final bool showLabel;
}

enum FollowButtonVisibility {
  always,
  keepUntilRefresh,
}
