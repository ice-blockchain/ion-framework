// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

class GradientBorderPainter extends CustomPainter {
  GradientBorderPainter({
    required this.gradient,
    this.strokeWidth = 2,
    this.cornerRadius = 12,
  });

  final Gradient gradient;
  final double strokeWidth;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
