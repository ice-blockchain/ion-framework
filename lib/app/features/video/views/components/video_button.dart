// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class VideoButton extends StatelessWidget {
  const VideoButton({
    required this.icon,
    this.onPressed,
    this.size,
    this.borderRadius,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double? size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: (size ?? 36.0).s,
        width: (size ?? 36.0).s,
        decoration: borderRadius == null
            ? BoxDecoration(
                color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              )
            : BoxDecoration(
                color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
                borderRadius: borderRadius,
              ),
        child: Center(
          child: icon,
        ),
      ),
    );
  }
}
