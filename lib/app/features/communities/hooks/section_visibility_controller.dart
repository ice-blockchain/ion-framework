import 'package:flutter/widgets.dart';
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
      if (_visibility[i] == true) return i;
    }
    return null;
  }

  void forceActivate(int index) {
    activeTabIndexNotifier.value = index;
  }
}

/// Result object that the hook returns.
/// Very clean API for the widget using it.
class SectionVisibilityState {
  SectionVisibilityState({
    required this.activeIndex,
    required this.callbacks,
    required this.controller,
  });

  /// Current active tab index (listen to this).
  final ValueNotifier<int> activeIndex;

  /// Visibility callbacks for each section.
  final List<ValueChanged<double>> callbacks;

  /// The internal controller (exposed in case you need overrides).
  final SectionVisibilityController controller;

  /// Manually activate a tab by index.
  /// Use this when user taps a tab to provide immediate feedback.
  void activateTab(int index) {
    controller.forceActivate(index);
  }
}

/// Hook to manage section visibility + active tab index.
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
