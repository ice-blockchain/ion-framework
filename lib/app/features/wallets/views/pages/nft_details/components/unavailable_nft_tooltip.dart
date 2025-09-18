// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class UnavailableNftTooltipOverlay extends StatelessWidget {
  const UnavailableNftTooltipOverlay({
    required this.opacityAnimation,
    required this.scaleAnimation,
    super.key,
  });

  final Animation<double> opacityAnimation;
  final Animation<double> scaleAnimation;

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
                      padding: EdgeInsets.symmetric(horizontal: 32.0.s, vertical: 11.0.s),
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
                      constraints: BoxConstraints(
                        maxWidth: 300.0.s,
                        maxHeight: 76.0.s,
                      ),
                      child: Text(
                        context.i18n.send_nft_sending_nft_will_be_available_later,
                        style: context.theme.appTextThemes.body2.copyWith(
                          color: context.theme.appColors.secondaryText,
                        ),
                      ),
                    ),
                    _TrianglePointer(
                      color: context.theme.appColors.onPrimaryAccent,
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
  const _TrianglePointer({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(12.s, 10.s),
      painter: _TrianglePainter(color: color),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
