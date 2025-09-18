// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

abstract class ShapeBuilder {
  const ShapeBuilder();

  Path build(Size size);
}

class ShapeClipper extends CustomClipper<Path> {
  ShapeClipper(this.shapeBuilder);

  final ShapeBuilder shapeBuilder;

  @override
  Path getClip(Size size) {
    return shapeBuilder.build(size);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class ShapePainter extends CustomPainter {
  ShapePainter(
    this.shapeBuilder, {
    this.color,
    this.shader,
  });

  final Color? color;

  final Shader? shader;

  final ShapeBuilder shapeBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.transparent
      ..shader = shader
      ..style = PaintingStyle.fill;

    final path = shapeBuilder.build(size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return color != oldDelegate.color || shader != oldDelegate.shader;
  }
}
