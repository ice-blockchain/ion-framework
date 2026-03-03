// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/num.dart';

enum ScreenOffsetSide { left, right }

class ScreenSideOffset extends StatelessWidget {
  const ScreenSideOffset._({
    required this.child,
    required this.margin,
    super.key,
    this.only,
  });

  factory ScreenSideOffset.large({
    required Widget child,
    Key? key,
    ScreenOffsetSide? only,
  }) {
    return ScreenSideOffset._(
      key: key,
      margin: defaultLargeMargin,
      only: only,
      child: child,
    );
  }

  factory ScreenSideOffset.medium({
    required Widget child,
    Key? key,
    ScreenOffsetSide? only,
  }) {
    return ScreenSideOffset._(
      key: key,
      margin: defaultMediumMargin,
      only: only,
      child: child,
    );
  }

  factory ScreenSideOffset.small({
    required Widget child,
    Key? key,
    ScreenOffsetSide? only,
  }) {
    return ScreenSideOffset._(
      key: key,
      margin: defaultSmallMargin,
      only: only,
      child: child,
    );
  }

  static double get defaultSmallMargin => 16.0.s;

  static double get defaultMediumMargin => 28.0.s;

  static double get defaultLargeMargin => 44.0.s;

  final Widget child;
  final double margin;
  final ScreenOffsetSide? only;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: only != null
          ? only == ScreenOffsetSide.left
              ? EdgeInsetsDirectional.only(start: margin)
              : EdgeInsetsDirectional.only(end: margin)
          : EdgeInsets.symmetric(horizontal: margin),
      child: child,
    );
  }
}
