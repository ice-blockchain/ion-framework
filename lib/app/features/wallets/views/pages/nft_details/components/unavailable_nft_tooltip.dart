// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shapes/shape.dart';
import 'package:ion/app/components/shapes/triangle_path.dart';
import 'package:ion/app/extensions/extensions.dart';

class UnavailableNftTooltipOverlay extends StatelessWidget {
  const UnavailableNftTooltipOverlay({
    required this.opacityAnimation,
    required this.scaleAnimation,
    required this.message,
    required this.maxWidth,
    required this.contentPadding,
    required this.triangleHeight,
    super.key,
  });

  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;
  final String? message;
  final double maxWidth;
  final EdgeInsets contentPadding;
  final double triangleHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([opacityAnimation, scaleAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: opacityAnimation.value,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: contentPadding,
                      decoration: BoxDecoration(
                        color: context.theme.appColors.onPrimaryAccent,
                        borderRadius: BorderRadius.circular(16.0.s),
                        boxShadow: [
                          BoxShadow(
                            color: context.theme.appColors.primaryText.withValues(alpha: 0.08),
                            blurRadius: 16.0.s,
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Text(
                        message ?? context.i18n.send_nft_sending_nft_will_be_available_later,
                        style: context.theme.appTextThemes.body2.copyWith(
                          color: context.theme.appColors.secondaryText,
                        ),
                      ),
                    ),
                    _TrianglePointer(
                      color: context.theme.appColors.onPrimaryAccent,
                      height: triangleHeight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrianglePointer extends StatelessWidget {
  const _TrianglePointer({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(12.s, height),
      painter: ShapePainter(
        const TriangleShapeBuilder(),
        color: color,
      ),
    );
  }
}
