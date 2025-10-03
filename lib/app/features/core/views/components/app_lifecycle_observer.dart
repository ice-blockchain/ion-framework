// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

class AppLifecycleObserver extends HookConsumerWidget {
  const AppLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnAppLifecycleStateChange((AppLifecycleState? previous, AppLifecycleState current) {
      ref.read(appLifecycleProvider.notifier).newState = current;
      Logger.log(
        '[LIFECYCLE] App lifecycle changed from: $previous to: $current',
      );

      if (current == AppLifecycleState.resumed) {
        ref.read(permissionsProvider.notifier).checkAllPermissions();
      }
    });

    return child;
  }
}

void onAppStateChange(Ref ref, void Function()? onBackground, void Function()? onForeground) {
  ref.listen(appLifecycleProvider, (prev, next) {
    if (prev == AppLifecycleState.paused && next == AppLifecycleState.resumed) {
      onForeground?.call();
    } else if (prev != null && next == AppLifecycleState.paused) {
      onBackground?.call();
    }
  });
}
