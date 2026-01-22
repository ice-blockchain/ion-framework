// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

// Converts pixel coordinates to data coordinates based on transformation matrix.
({double startX, double endX}) calculateVisibleDataRange(
  Matrix4 matrix,
  double drawableWidth,
  double maxX,
) {
  final scaleX = matrix.storage[0];
  final translateX = matrix.storage[12];
  final dataPerPixel = maxX / drawableWidth;

  final startX = ((-translateX / scaleX) * dataPerPixel).clamp(0.0, maxX);
  final endX = (((-translateX + drawableWidth) / scaleX) * dataPerPixel).clamp(0.0, maxX);

  return (startX: startX, endX: endX);
}
