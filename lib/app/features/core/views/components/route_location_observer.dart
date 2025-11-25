// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';

class RouteLocationObserver extends HookConsumerWidget {
  const RouteLocationObserver({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.maybeOf(rootNavigatorKey.currentContext ?? context);

    useEffect(
      () {
        if (router == null) {
          return () => {};
        }
        void onRouteChanged() {
          final fullPath = router.state.fullPath ?? '';
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              ref.read(routeLocationProvider.notifier).setLocation(fullPath);
            },
          );
        }

        // push initial route
        onRouteChanged();

        final delegate = router.routerDelegate..addListener(onRouteChanged);

        return () {
          delegate.removeListener(onRouteChanged);
        };
      },
      [router],
    );

    return child;
  }
}
