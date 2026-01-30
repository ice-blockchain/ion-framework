// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';

bool isContextVisible(BuildContext context) {
  final renderObject = context.findRenderObject();

  if (renderObject == null || renderObject is! RenderBox) return true;

  final scrollables = _ancestorScrollables(context);
  if (scrollables.isEmpty) {
    return true;
  }
  for (final scrollable in scrollables) {
    final targetRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final viewportObject = scrollable.context.findRenderObject();
    if (viewportObject is! RenderBox) {
      continue;
    }
    final viewportRect = viewportObject.localToGlobal(Offset.zero) & viewportObject.size;

    if (!viewportRect.contains(targetRect.topLeft) ||
        !viewportRect.contains(targetRect.bottomRight)) {
      return false;
    }
  }

  return true;
}

List<ScrollableState> _ancestorScrollables(BuildContext context) {
  final scrollables = <ScrollableState>[];
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScrollableState) {
      scrollables.add(element.state as ScrollableState);
    }
    return true;
  });
  return scrollables;
}
