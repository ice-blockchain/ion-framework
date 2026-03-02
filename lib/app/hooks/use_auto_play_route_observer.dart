// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';

void _afterFrame(VoidCallback action) {
  WidgetsBinding.instance.addPostFrameCallback((_) => action());
}

void useAutoPlayRouteObserver(
  VideoPlayerController? controller, {
  RouteObserver<ModalRoute<void>>? routeObserver,
}) {
  final context = useContext();
  final route = ModalRoute.of(context);

  useEffect(
    () {
      final observer = _RouteObserverCallback(
        didPushNextCallback: () => _afterFrame(() => controller?.pause()),
        didPopNextCallback: () => _afterFrame(() => controller?.play()),
      );

      if (routeObserver != null && route is ModalRoute<void>) {
        routeObserver.subscribe(observer, route);
      }

      _afterFrame(() => controller?.play());

      return () {
        if (routeObserver != null) {
          routeObserver.unsubscribe(observer);
        }
        _afterFrame(() => controller?.pause());
      };
    },
    [controller, routeObserver, route],
  );
}

class _RouteObserverCallback extends RouteAware {
  _RouteObserverCallback({
    this.didPushNextCallback,
    this.didPopNextCallback,
  });

  final VoidCallback? didPushNextCallback;
  final VoidCallback? didPopNextCallback;

  @override
  void didPushNext() {
    didPushNextCallback?.call();
  }

  @override
  void didPopNext() {
    didPopNextCallback?.call();
  }
}
