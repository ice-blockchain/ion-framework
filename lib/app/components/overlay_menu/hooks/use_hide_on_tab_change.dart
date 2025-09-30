// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/router/main_tabs/components/main_tab_navigation_container.dart';

void useHideOnTabChange(
  BuildContext context,
  OverlayPortalController overlayPortalController,
) {
  final tabPressStream = MainTabNavigationContainer.of(context).tabPressStream;

  useEffect(
    () {
      final listener = tabPressStream.listen((tabPressData) {
        if (!overlayPortalController.isShowing) return;

        if (context.mounted && overlayPortalController.isShowing) {
          overlayPortalController.hide();
        }
      });

      return listener.cancel;
    },
    [overlayPortalController],
  );
}
