// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:riverpod/riverpod.dart';

enum AppLifecycleStatus {
  resumed,
  inactive,
  hidden,
  paused,
  detached,
}

extension RefLifecycleListenExtension on Ref {
  void listenOnLifecycleTransition({
    required void Function(AppLifecycleStatus? previous, AppLifecycleStatus current) onTransition,
    AppLifecycleStatus? from,
    AppLifecycleStatus? to,
    bool fireImmediately = false,
  }) {
    listen(
      appLifecycleProvider,
      (previous, next) {
        final prev = previous == null ? null : _mapAppLifecycleState(previous);
        final curr = _mapAppLifecycleState(next);
        if (prev != null && prev == curr) return;
        if (from != null && prev != from) return;
        if (to != null && curr != to) return;
        onTransition(prev, curr);
      },
      fireImmediately: fireImmediately,
    );
  }
}

AppLifecycleStatus _mapAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.resumed:
      return AppLifecycleStatus.resumed;
    case AppLifecycleState.inactive:
      return AppLifecycleStatus.inactive;
    case AppLifecycleState.hidden:
      return AppLifecycleStatus.hidden;
    case AppLifecycleState.paused:
      return AppLifecycleStatus.paused;
    case AppLifecycleState.detached:
      return AppLifecycleStatus.detached;
  }
}
