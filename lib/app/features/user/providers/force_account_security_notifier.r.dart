// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/views/pages/secure_account_modal.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'force_account_security_notifier.r.g.dart';

@Riverpod(keepAlive: true)
class ForceAccountSecurityNotifier extends _$ForceAccountSecurityNotifier {
  Timer? _timer;
  bool _wired = false;

  @override
  Future<void> build() async {
    if (!_wired) {
      _wired = true;
      listenSelf((previous, next) {
        _timer?.cancel();
        _timer = null;
      });
      ref.onDispose(() {
        _timer?.cancel();
      });
    }

    final isSplashAnimationCompleted = ref.watch(splashProvider);
    if (!isSplashAnimationCompleted) {
      return;
    }

    final currentContext = rootNavigatorKey.currentContext;
    if (currentContext == null) {
      return;
    }

    final isAuthenticated = ref.watch(authProvider).value?.isAuthenticated ?? false;
    if (!isAuthenticated) {
      return;
    }

    final masterPubkey = ref.watch(currentPubkeySelectorProvider);
    final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;
    if (masterPubkey == null || !delegationComplete) {
      return;
    }

    final userMetadata = ref.watch(currentUserMetadataProvider).valueOrNull;
    if (userMetadata == null) {
      return;
    }

    final isAccountSecured = await ref.watch(isCurrentUserSecuredProvider.future);
    if (isAccountSecured) {
      return;
    }

    final appLifecycleState = ref.watch(appLifecycleProvider);
    if (appLifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final currentPath = ref.watch(routeLocationProvider);
    final isOnFeed = currentPath == FeedRoute().location;
    if (!isOnFeed) {
      return;
    }

    final enforceDelayDuration = ref.read(envProvider.notifier).get<Duration>(
          EnvVariable.ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES,
        );
    final enforceTime = userMetadata.createdAt.toDateTime.add(enforceDelayDuration);
    final now = DateTime.now();
    final canShowPopUp = enforceTime.isBefore(now);
    if (!canShowPopUp) {
      final remaining = enforceTime.difference(now);
      final duration = remaining.isNegative ? Duration.zero : remaining;
      _timer?.cancel();
      _timer = Timer(duration, () {
        ref.invalidateSelf();
      });
      return;
    }

    ref.read(uiEventQueueNotifierProvider.notifier).emit(const SecureAccountDialogEvent());
  }
}
