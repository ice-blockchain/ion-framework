// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

VoidCallback usePopUntil({
  required String routeLocation,
}) {
  final context = useContext();
  return useCallback(
    () {
      Future<void> popUntil() async {
        final router = context.mounted ? GoRouter.maybeOf(context) : null;
        if (router == null) {
          return;
        }
        final state = router.state;
        final fullPath = state.fullPath;
        if (fullPath == routeLocation) {
          return;
        }
        if (!router.canPop()) {
          return;
        }
        router.pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          popUntil();
        });
      }

      popUntil();
    },
    [],
  );
}
