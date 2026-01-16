// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class BackGestureExclusionRegistry {
  static final Map<Route<dynamic>, Set<ValueListenable<Rect?>>> _entries = {};

  static void register(Route<dynamic> route, ValueListenable<Rect?> rectListenable) {
    _entries.putIfAbsent(route, () => <ValueListenable<Rect?>>{}).add(rectListenable);
  }

  static void unregister(Route<dynamic> route, ValueListenable<Rect?> rectListenable) {
    final entries = _entries[route];
    if (entries == null) {
      return;
    }

    entries.remove(rectListenable);
    if (entries.isEmpty) {
      _entries.remove(route);
    }
  }

  static bool isExcluded(Route<dynamic> route, Offset globalPosition) {
    final entries = _entries[route];
    if (entries == null) {
      return false;
    }

    for (final entry in entries) {
      final rect = entry.value;
      if (rect != null && rect.contains(globalPosition)) {
        return true;
      }
    }

    return false;
  }
}
