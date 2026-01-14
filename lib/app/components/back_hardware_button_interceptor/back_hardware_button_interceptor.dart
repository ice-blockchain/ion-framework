// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BackHardwareButtonInterceptor extends HookWidget {
  const BackHardwareButtonInterceptor({
    required this.child,
    required this.onBackPress,
    super.key,
  });
  final Widget child;
  final Future<void> Function(BuildContext context) onBackPress;

  @override
  Widget build(BuildContext context) {
    final handleBackButton = useCallback(
      ({
        required bool stop,
        required RouteInfo info,
        required BuildContext context,
      }) async {
        if (info.ifRouteChanged(context)) {
          return false;
        } else {
          await onBackPress(context);
          return true;
        }
      },
      [onBackPress],
    );

    final backButtonInterceptor = useCallback(
      (bool stop, RouteInfo info) {
        return handleBackButton(
          stop: stop,
          info: info,
          context: info.routeWhenAdded?.navigator?.context ?? context,
        );
      },
      [handleBackButton],
    );

    useEffect(
      () {
        BackButtonInterceptor.add(backButtonInterceptor, context: context);
        return () => BackButtonInterceptor.remove(backButtonInterceptor);
      },
      [backButtonInterceptor],
    );

    return child;
  }
}
