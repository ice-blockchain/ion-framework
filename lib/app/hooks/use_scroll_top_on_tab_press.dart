// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/main_tabs/components/main_tab_navigation_container.dart';

void useScrollTopOnTabPress(
  BuildContext context, {
  required ScrollController scrollController,
  bool enabled = true,
}) {
  final tabPressStream = MainTabNavigationContainer.of(context).tabPressStream;

  useEffect(
    () {
      if (!enabled) return null;

      final listener = tabPressStream.listen((tabPressData) {
        // taking the GoRouterState here instead of out of listener,
        // because otherwise it is considered the same even if the screen is changed
        if (!context.mounted) return;
        final routerState = GoRouterState.of(context);
        if (
            // if we pressed the same tab we're currently on
            tabPressData.current == tabPressData.pressed &&
                // if we pressed the tab that our page belongs to
                tabPressData.pressed == routerState.currentTab &&
                // if we're on the root tab page
                routerState.topRoute?.path == routerState.fullPath) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
      return listener.cancel;
    },
    [tabPressStream, enabled],
  );
}
