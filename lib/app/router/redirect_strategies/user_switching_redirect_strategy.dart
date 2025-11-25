// SPDX-License-Identifier: ice License 1.0

// lib/app/router/redirect_strategies/user_switching_redirect_strategy.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/redirect_strategies/redirect_strategy.dart';
import 'package:ion/app/services/database/database_ready_notifier.r.dart';

class UserSwitchingRedirectStrategy implements RedirectStrategy {
  @override
  Future<String?> getRedirect({
    required String location,
    required Ref ref,
  }) async {
    final isUserSwitching = ref.read(userSwitchingProvider);
    if (!isUserSwitching) {
      return null;
    }

    final isAuthenticated = (ref.read(authProvider).valueOrNull?.isAuthenticated).falseOrValue;
    final isDatabasesReady = ref.read(databasesReadyNotifierProvider).falseOrValue;

    if (isAuthenticated && isDatabasesReady) {
      ref.read(userSwitchingProvider.notifier).reset();
      return null;
    } else {
      return SwitchUserLoaderRoute().location;
    }
  }
}
