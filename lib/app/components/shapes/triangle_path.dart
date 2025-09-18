// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/shapes/shape.dart';

class TriangleShapeBuilder extends ShapeBuilder {
  const TriangleShapeBuilder();

  @override
  Path build(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
  }
}
