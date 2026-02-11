// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/verify_identity/passkey_dialog_state.dart';
import 'package:ion/app/services/logger/logger.dart';
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
void onAppWentToBackground(Ref ref, FutureOr<void> Function() callback) {
  ref.listen<AppLifecycleState>(appLifecycleProvider, (prev, next) {
    if (prev == AppLifecycleState.resumed &&
        next != AppLifecycleState.resumed &&
        !GlobalPasskeyDialogState.isShowing) {
      try {
        final result = callback();
        if (result is Future) {
          unawaited(
            result.catchError((Object error, StackTrace stackTrace) {
              Logger.log('onAppWentToBackground callback failed', error: error);
            }),
          );
        }
      } catch (error) {
        Logger.log('onAppWentToBackground callback failed', error: error);
      }
    }
  });
}
