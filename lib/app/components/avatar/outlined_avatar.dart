// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/avatar_constants.dart';
import 'package:ion/app/components/gradient_border_painter/gradient_border_painter.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';

class OutlinedAvatar extends StatelessWidget {
  const OutlinedAvatar({
    required this.size,
    required this.gradient,
    required this.pubkey,
    this.borderRadius,
    this.imageUrl,
    this.imageWidget,
    this.defaultAvatar,
    this.fit,
    super.key,
  });

  final double size;
  final Gradient gradient;
  final String pubkey;
  final BorderRadiusGeometry? borderRadius;
  final String? imageUrl;
  final Widget? imageWidget;
  final Widget? defaultAvatar;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final outerRadius = _getRadius(borderRadius, size);
    final borderWidth = size * _ProfileOutlineConstants.borderWidthRatio;
    final padding = size * _ProfileOutlineConstants.paddingRatio;
    final innerSize = size - padding * 2;
    final innerRadius = innerSize * _ProfileOutlineConstants.borderRadiusRatio;

    final innerAvatar = imageUrl != null || imageWidget != null || defaultAvatar != null
        ? Avatar(
            size: innerSize,
            imageUrl: imageUrl,
            imageWidget: imageWidget,
            defaultAvatar: defaultAvatar,
            borderRadius: BorderRadius.circular(innerRadius),
            fit: fit,
          )
        : IonConnectAvatar(
            size: innerSize,
            fit: fit,
            masterPubkey: pubkey,
            borderRadius: BorderRadius.circular(innerRadius),
          );

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: GradientBorderPainter(
          gradient: gradient,
          strokeWidth: borderWidth,
          cornerRadius: outerRadius,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: innerAvatar,
        ),
      ),
    );
  }

  double _getRadius(BorderRadiusGeometry? borderRadius, double size) {
    if (borderRadius is BorderRadius) {
      return borderRadius.topRight.x;
    }
    return size * _ProfileOutlineConstants.borderRadiusRatio;
  }
}

// Constants for profile outline proportions
class _ProfileOutlineConstants {
  _ProfileOutlineConstants._();

  // Border width ratio: 0.025
  static const double borderWidthRatio = 0.03;

  // Padding between border and avatar ratio: 0.05
  static const double paddingRatio = 0.05;

  static const double borderRadiusRatio = 0.23;
}
