// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

/// A ShapeBorder that creates a rounded rectangle with a smooth notch at the bottom center.
/// The notch uses smooth circular arcs, designed to accommodate a floating button.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: ShapeDecoration(
///     color: Colors.blue,
///     shape: BottomNotchRectBorder(
///       cornerRadius: 12.0,
///       notchWidth: 96.0,
///       notchDepth: 12.0,
///     ),
///   ),
///   child: ...
/// )
/// ```
class BottomNotchRectBorder extends ShapeBorder {
  const BottomNotchRectBorder({
    this.cornerRadius,
    this.notchWidth,
    this.notchDepth,
    this.isOnTop = false,
  });

  final double? cornerRadius;
  final double? notchWidth;
  final double? notchDepth;
  final bool isOnTop;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  Path _buildPath(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final r = cornerRadius ?? 12.0.s;
    final left = rect.left;
    final top = rect.top;

    final effectiveNotchWidth = notchWidth ?? 108.s;
    final effectiveNotchDepth = notchDepth ?? 8.s;

    final notchCenterX = left + w / 2;
    final bottom = top + h;
    final curveWidth = effectiveNotchDepth * 2.5;

    final flatMiddleHalf = (effectiveNotchWidth - 2 * curveWidth) / 2;

    final path = Path()..moveTo(left + r, top);

    _connectEdge(
      path,
      left + r,
      left + w - r,
      top,
      isOnTop,
      true,
      notchCenterX,
      flatMiddleHalf,
      curveWidth,
      effectiveNotchDepth,
    );

    path
      ..quadraticBezierTo(left + w, top, left + w, top + r)
      ..lineTo(left + w, bottom - r)
      ..quadraticBezierTo(left + w, bottom, left + w - r, bottom);

    _connectEdge(
      path,
      left + w - r,
      left + r,
      bottom,
      !isOnTop,
      false,
      notchCenterX,
      flatMiddleHalf,
      curveWidth,
      effectiveNotchDepth,
    );

    path
      ..quadraticBezierTo(left, bottom, left, bottom - r)
      ..lineTo(left, top + r)
      ..quadraticBezierTo(left, top, left + r, top)
      ..close();
    return path;
  }

  void _connectEdge(
    Path path,
    double startX,
    double endX,
    double y,
    bool hasNotch,
    bool isTop,
    double centerX,
    double flatHalf,
    double curveW,
    double depth,
  ) {
    if (!hasNotch) {
      path.lineTo(endX, y);
      return;
    }

    final dx = isTop ? 1.0 : -1.0;
    final dy = isTop ? 1.0 : -1.0;

    final notchStartX = centerX - (flatHalf + curveW) * dx;

    path
      ..lineTo(notchStartX, y)
      ..relativeCubicTo(
        (curveW / 2) * dx, 0, // CP1
        (curveW / 2) * dx, depth * dy, // CP2
        curveW * dx, depth * dy, // End
      )
      ..lineTo(centerX + flatHalf * dx, y + depth * dy)
      ..relativeCubicTo(
        (curveW / 2) * dx, 0, // CP1
        (curveW / 2) * dx, -depth * dy, // CP2
        curveW * dx, -depth * dy, // End
      )
      ..lineTo(endX, y);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // No border painting needed - the shape itself is the decoration
  }

  @override
  ShapeBorder scale(double t) {
    return BottomNotchRectBorder(
      cornerRadius: (cornerRadius ?? 12.0.s) * t,
      notchWidth: (notchWidth ?? 108.s) * t,
      notchDepth: (notchDepth ?? 8.s) * t,
      isOnTop: isOnTop,
    );
  }
}
