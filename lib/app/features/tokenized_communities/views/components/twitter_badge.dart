// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

/// A widget that displays a Twitter/X logo badge.
///
/// Can be displayed as a container with background or as a standalone icon.
/// Supports various styling options including size, padding, border, and colors.
class TwitterBadge extends StatelessWidget {
  const TwitterBadge({
    required this.iconSize,
    this.iconColor,
    this.containerSize,
    this.padding,
    this.borderRadius,
    this.border,
    this.showContainer = true,
    super.key,
  });

  /// Size of the Twitter/X icon.
  final double iconSize;

  /// Color of the Twitter/X icon.
  /// If null, defaults to white when container is shown, or theme default when icon-only.
  final Color? iconColor;

  /// Fixed size for the container (width and height).
  /// If provided, padding is ignored.
  final double? containerSize;

  /// Padding for the container.
  /// Used when containerSize is not provided.
  final EdgeInsets? padding;

  /// Border radius for the container.
  /// Defaults to 4.0.s if not specified.
  final double? borderRadius;

  /// Optional border for the container.
  final Border? border;

  /// Whether to show the container around the icon.
  /// Set to false for icon-only mode.
  final bool showContainer;

  @override
  Widget build(BuildContext context) {
    final icon = Assets.svg.iconLoginXlogo.icon(
      size: iconSize,
      color: iconColor ?? (showContainer ? Colors.white : null),
    );

    if (!showContainer) {
      return icon;
    }

    final decoration = BoxDecoration(
      color: context.theme.appColors.asphalt,
      borderRadius: BorderRadius.circular(borderRadius ?? 4.0.s),
      border: border,
    );

    if (containerSize != null) {
      return Container(
        width: containerSize,
        height: containerSize,
        decoration: decoration,
        child: Center(child: icon),
      );
    }

    return Container(
      padding: padding,
      decoration: decoration,
      child: icon,
    );
  }
}
