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

  void update(int index, double fraction) {
    final isVisible = fraction > 0;
    _visibility[index] = isVisible;

    final newIndex = _findLowestVisibleIndex();
    if (newIndex != null && newIndex != activeTabIndexNotifier.value) {
      activeTabIndexNotifier.value = newIndex;
    }
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
