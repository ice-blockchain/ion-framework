// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A hook that calculates and returns the scroll progress for a scroll controller.
///
/// Returns a value between 0.05 and 1.0 representing the scroll progress.
/// - 0.05: At the top of the scrollable content
/// - 1.0: At the bottom or when content doesn't scroll
///
/// If [totalContentHeight] is provided, it will be used to calculate the max scroll extent
/// instead of relying on [ScrollController.position.maxScrollExtent]. This is useful when
/// the content height is pre-calculated (e.g., via offscreen measurement).
double useScrollIndicator(
  ScrollController scrollController, {
  double? totalContentHeight,
}) {
  final progress = useState<double>(0);

  useEffect(
    () {
      var isDisposed = false;

      void calculateProgress() {
        if (isDisposed || !scrollController.hasClients) return;

        try {
          final position = scrollController.position;
          final viewportHeight = position.viewportDimension;
          final currentScroll = scrollController.offset;

          final maxScroll = totalContentHeight != null && totalContentHeight > 0
              ? (totalContentHeight - viewportHeight).clamp(0.0, double.infinity)
              : position.maxScrollExtent;

          if (maxScroll > 0) {
            final scrollFraction = (currentScroll / maxScroll).clamp(0.0, 1.0);
            progress.value = 0.05 + (0.95 * scrollFraction);
          } else {
            progress.value = 1.0;
          }
        } catch (e) {
          return;
        }
      }

      void onInitialFrame() {
        if (isDisposed) return;

        if (scrollController.hasClients) {
          try {
            final position = scrollController.position;
            if (totalContentHeight != null && totalContentHeight > 0) {
              calculateProgress();
            } else if (position.maxScrollExtent > 0) {
              calculateProgress();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
            }
          } catch (e) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());

      scrollController.addListener(calculateProgress);
      return () {
        isDisposed = true;
        scrollController.removeListener(calculateProgress);
      };
    },
    [scrollController, totalContentHeight],
  );

  return progress.value;
}
