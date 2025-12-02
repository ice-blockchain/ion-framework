// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SectionVisibilityController {
  SectionVisibilityController(
    this.activeTabIndexNotifier,
    this.tabCount,
  );

  final ValueNotifier<int> activeTabIndexNotifier;
  final int tabCount;

  final Map<int, bool> _visibility = {};
  bool _ignoreVisibilityUpdates = false;
  Timer? _ignoreTimer;

  static const double _visibilityThreshold = 0.3; // 30% visible

  void update(int index, double fraction) {
    // When threshold is 0, use strict > to avoid treating 0% as visible
    // When threshold > 0, use >= to include threshold value
    final isVisible = _visibilityThreshold == 0 ? fraction > 0 : fraction >= _visibilityThreshold;
    _visibility[index] = isVisible;

    if (_ignoreVisibilityUpdates) {
      return;
    }

    final newIndex = _findLowestVisibleIndex();
    if (newIndex != null && newIndex != activeTabIndexNotifier.value) {
      activeTabIndexNotifier.value = newIndex;
    }
  }

  // Temporarily ignore visibility updates for the given duration.
  // Used to prevent visibility detection from interfering with programmatic scrolls.
  void ignoreUpdatesFor(Duration duration) {
    _ignoreVisibilityUpdates = true;
    _ignoreTimer?.cancel();
    _ignoreTimer = Timer(duration, () {
      _ignoreVisibilityUpdates = false;
    });
  }

  void dispose() {
    _ignoreTimer?.cancel();
    _ignoreTimer = null;
  }

  int? _findLowestVisibleIndex() {
    if (_visibility.isEmpty) return null;
    for (var i = 0; i < tabCount; i++) {
      if (_visibility[i] ?? false) return i;
    }
    return null;
  }
}

class SectionVisibilityState {
  SectionVisibilityState({
    required this.activeIndex,
    required this.callbacks,
    required this.controller,
  });

  final ValueNotifier<int> activeIndex;
  final List<ValueChanged<double>> callbacks;
  final SectionVisibilityController controller;

  ValueChanged<int> createScrollToSection(
    List<GlobalKey> sectionKeys, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return (int index) {
      // Optimistic update: activate tab immediately for instant UI feedback
      activeIndex.value = index;

      // Ignore visibility updates during scroll animation + buffer to prevent
      // visibility detection from switching tabs back during the scroll
      controller.ignoreUpdatesFor(
        duration + const Duration(milliseconds: 100), // 100ms buffer after scroll completes
      );

      // Scroll to the section
      final key = sectionKeys[index];
      final sectionContext = key.currentContext;
      if (sectionContext != null) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: duration,
          curve: curve,
        );
      }
    };
  }
}

// Hook to manage section visibility + active tab index.
SectionVisibilityState useSectionVisibilityController(int tabCount) {
  final activeIndex = useState(0);

  // Create controller only once
  final controller = useMemoized(
    () => SectionVisibilityController(activeIndex, tabCount),
    [activeIndex, tabCount],
  );

  // Generate visibility callbacks once
  final callbacks = useMemoized(
    () => List<ValueChanged<double>>.generate(
      tabCount,
      (index) => (double fraction) => controller.update(index, fraction),
    ),
    [controller],
  );

  return SectionVisibilityState(
    activeIndex: activeIndex,
    callbacks: callbacks,
    controller: controller,
  );
}
