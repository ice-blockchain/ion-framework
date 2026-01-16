// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class GradientBorderPainter extends CustomPainter {
  GradientBorderPainter({
    required this.gradient,
    this.strokeWidth = 2,
    this.cornerRadius = 12,
    this.backgroundColor,
  });

  final Gradient gradient;
  final double strokeWidth;
  final double cornerRadius;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // Draw background if color is provided
    if (backgroundColor != null) {
      final backgroundPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rrect, backgroundPaint);
    }

    // Draw gradient border
    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
