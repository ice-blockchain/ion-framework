// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

bool isContextVisible(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject == null || renderObject is! RenderBox) return true;
  final viewport = RenderAbstractViewport.maybeOf(renderObject);
  if (viewport == null) return true;
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) return true;
  final position = scrollable.position;
  final offsetToRevealTop = viewport.getOffsetToReveal(renderObject, 0).offset;
  final offsetToRevealBottom = viewport.getOffsetToReveal(renderObject, 1).offset;
  final currentOffset = position.pixels;
  return currentOffset >= offsetToRevealTop && currentOffset <= offsetToRevealBottom;
}

Future<void> ensureContextVisible(
  BuildContext context, {
  Duration duration = const Duration(milliseconds: 200),
  Curve curve = Curves.easeInOut,
  double alignment = 0.0,
}) async {
  if (isContextVisible(context)) return;
  await Scrollable.ensureVisible(
    context,
    alignment: alignment,
    duration: duration,
    curve: curve,
  );
}
