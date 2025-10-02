// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/router/main_tabs/components/main_tab_navigation_container.dart';

void useHideOnTabChange(
  BuildContext context,
  OverlayPortalController overlayPortalController,
) {
  final mainTabNavigationContainer =
      useMemoized(() => MainTabNavigationContainer.maybeOf(context), [context]);
  final tabPressStream = mainTabNavigationContainer?.tabPressStream;

  useEffect(
    () {
      StreamSubscription<TabPressSteamData>? listener;
      if (tabPressStream != null) {
        listener = tabPressStream.listen((tabPressData) {
          if (overlayPortalController.isShowing && context.mounted) {
            overlayPortalController.hide();
          }
        });
      }

      return () async {
        if (listener != null) {
          await listener.cancel();
        }
      };
    },
    [overlayPortalController, tabPressStream, context],
  );
}
