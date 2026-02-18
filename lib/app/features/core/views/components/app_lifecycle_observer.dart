// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

class AppLifecycleObserver extends HookConsumerWidget {
  const AppLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnAppLifecycleStateChange((AppLifecycleState? previous, AppLifecycleState current) {
      ref.read(appLifecycleProvider.notifier).newState = current;

      final currentRoute = ref.read(routeLocationProvider);
      Logger.log(
        '[LIFECYCLE] App lifecycle changed from: $previous to: $current (route: $currentRoute)',
      );

      if (current == AppLifecycleState.resumed) {
        Logger.log('[LIFECYCLE] App resumed on route: $currentRoute');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final routeAfterFrame = ref.read(routeLocationProvider);
          Logger.log('[LIFECYCLE] First frame after resume rendered (route: $routeAfterFrame)');
        });

        ref.read(permissionsProvider.notifier).checkAllPermissions();
      }
    });

    return child;
  }
}
