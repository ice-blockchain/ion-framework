// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle_provider.r.g.dart';

@Riverpod(keepAlive: true)
class AppLifecycle extends _$AppLifecycle {
  @override
  AppLifecycleState build() {
    return AppLifecycleState.resumed;
  }

  set newState(AppLifecycleState newState) {
    state = newState;
  }
}

/// Calls [callback] when the app transitions to the background
/// (i.e. the previous state was [AppLifecycleState.resumed] and the new state is not).
void onAppWentToBackground(Ref ref, void Function() callback) {
  ref.listen<AppLifecycleState>(appLifecycleProvider, (prev, next) {
    if (prev == AppLifecycleState.resumed && next != AppLifecycleState.resumed) {
      callback();
    }
  });
}
