// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void useHideOnScroll(
  BuildContext context,
  OverlayPortalController overlayPortalController,
  ScrollController? scrollController,
) {
  useEffect(
    () {
      final isScrollingNotifier =
          scrollController?.position.isScrollingNotifier ??
          Scrollable.maybeOf(context)?.position.isScrollingNotifier;

      void handleScrolling() {
        if (!overlayPortalController.isShowing) return;
        // Only hide when scrolling starts (value true), not when it stops (value false).
        // This allows opening the menu while scroll is active without it closing immediately.
        if (isScrollingNotifier?.value != true) return;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && overlayPortalController.isShowing) {
            overlayPortalController.hide();
          }
        });
      }

      isScrollingNotifier?.addListener(handleScrolling);

      return () => isScrollingNotifier?.removeListener(handleScrolling);
    },
    [overlayPortalController, scrollController],
  );
}
