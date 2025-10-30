// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A hook that calculates and returns the scroll progress for a scroll controller.
///
/// Returns a value between 0.05 and 1.0 representing the scroll progress.
/// - 0.05: At the top of the scrollable content
/// - 1.0: At the bottom or when content doesn't scroll
double useScrollIndicator(ScrollController scrollController) {
  final progress = useState<double>(0);

  useEffect(
    () {
      var isDisposed = false;

      void calculateProgress() {
        // Check if disposed or scroll controller not attached
        if (isDisposed || !scrollController.hasClients) return;

        try {
          final position = scrollController.position;
          final maxScroll = position.maxScrollExtent;
          final currentScroll = scrollController.offset;

          if (maxScroll > 0) {
            final scrollFraction = (currentScroll / maxScroll).clamp(0.0, 1.0);
            progress.value = 0.05 + (0.95 * scrollFraction);
          } else {
            progress.value = 1.0;
          }
        } catch (e) {
          // Ignore errors during disposal
          return;
        }
      }

      void onInitialFrame() {
        // Check if already disposed
        if (isDisposed) return;

        if (scrollController.hasClients) {
          try {
            final position = scrollController.position;
            if (position.maxScrollExtent > 0) {
              calculateProgress();
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
            }
          } catch (e) {
            // Position not ready yet, try again
            WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => onInitialFrame());

      scrollController.addListener(calculateProgress);
      return () {
        // Mark as disposed to stop all pending callbacks
        isDisposed = true;
        scrollController.removeListener(calculateProgress);
      };
    },
    [scrollController],
  );

  return progress.value;
}
