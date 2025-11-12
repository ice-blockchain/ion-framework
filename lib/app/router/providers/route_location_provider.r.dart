// SPDX-License-Identifier: ice License 1.0

import 'package:go_router/go_router.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_location_provider.r.g.dart';

@Riverpod(keepAlive: true)
class RouteLocation extends _$RouteLocation {
  bool _wired = false;

  @override
  String build() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return '';
    }

    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return '';
    }

    _ensureSubscribed(router);

    return router.state.fullPath ?? '';
  }

  void _ensureSubscribed(GoRouter router) {
    if (_wired) return;
    _wired = true;

    void onRouteChanged() {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final next = router.state.fullPath;
      if (next != null && state != next) {
        state = next;
      }
    }

    final delegate = router.routerDelegate..addListener(onRouteChanged);
    ref.onDispose(() => delegate.removeListener(onRouteChanged));
  }
}
