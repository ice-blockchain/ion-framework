// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/views/pages/secure_account_modal.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'force_account_security_notifier.r.g.dart';

class ForceAccountSecurityService {
  ForceAccountSecurityService({
    required Duration Function() getEnforceDelay,
    required void Function() emitDialog,
  })  : _getEnforceDelay = getEnforceDelay,
        _emitDialog = emitDialog;
  bool _authenticated = false;
  UserMetadataEntity? _metadata;
  bool _delegationComplete = false;
  bool _secured = false;
  String _route = '';
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _splashCompleted = false;
  String? _masterPubkey;

  final Duration Function() _getEnforceDelay;
  final void Function() _emitDialog;

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void onSplashCompleted({required bool splashCompleted}) {
    _splashCompleted = splashCompleted;
    _maybeTrigger();
  }

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  void onMasterPubkey(String? value) {
    _masterPubkey = value;
    _maybeTrigger();
  }

  void onUserMetadata(UserMetadataEntity? value) {
    _metadata = value;
    _maybeTrigger();
  }

  void onDelegationComplete({required bool delegationComplete}) {
    _delegationComplete = delegationComplete;
    _maybeTrigger();
  }

  void onSecured({required bool secured}) {
    _secured = secured;
    _maybeTrigger();
  }

  void onRouteChanged(String value) {
    _route = value;
    _maybeTrigger();
  }

  void onLifecycleChanged(AppLifecycleState value) {
    _lifecycle = value;
    _maybeTrigger();
  }

  void _maybeTrigger() {
    // 1. splash done
    if (!_splashCompleted) return;

    // 2. context exists
    if (rootNavigatorKey.currentContext == null) return;

    // 3. auth
    if (!_authenticated) return;

    // 4. delegation + masterPubkey
    if (_masterPubkey == null || !_delegationComplete) return;

    // 5. metadata
    if (_metadata == null) return;
    final metadata = _metadata!;

    // 6. secured?
    if (_secured) return;

    // 7. lifecycle
    if (_lifecycle != AppLifecycleState.resumed) return;

    // 8. route
    if (_route != FeedRoute().location) return;

    // 9. enforce time
    final enforceDelayDuration = _getEnforceDelay();
    final enforceTime = metadata.createdAt.toDateTime.add(enforceDelayDuration);
    final now = DateTime.now();
    final canShowPopUp = enforceTime.isBefore(now);

    if (!canShowPopUp) {
      final remaining = enforceTime.difference(now);
      final duration = remaining.isNegative ? Duration.zero : remaining;
      _timer?.cancel();
      _timer = Timer(duration, _maybeTrigger);
      return;
    }

    _timer?.cancel();
    _timer = null;

    // 10. emit dialog
    _emitDialog();
  }
}

@Riverpod(keepAlive: true)
ForceAccountSecurityService forceAccountSecurityService(Ref ref) {
  final service = ForceAccountSecurityService(
    getEnforceDelay: () => ref.read(envProvider.notifier).get<Duration>(
          EnvVariable.ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES,
        ),
    emitDialog: () {
      ref.read(uiEventQueueNotifierProvider.notifier).emit(const SecureAccountDialogEvent());
    },
  );

  ref.onDispose(service.dispose);

  // Seed initial values
  service
    ..onSplashCompleted(splashCompleted: ref.read(splashProvider))
    ..onAuthenticated(authenticated: ref.read(authProvider).value?.isAuthenticated ?? false)
    ..onMasterPubkey(ref.read(currentPubkeySelectorProvider))
    ..onUserMetadata(ref.read(currentUserMetadataProvider).valueOrNull)
    ..onDelegationComplete(
      delegationComplete: ref.read(delegationCompleteProvider).valueOrNull.falseOrValue,
    )
    ..onSecured(secured: ref.read(isCurrentUserSecuredProvider).valueOrNull ?? false)
    ..onRouteChanged(ref.read(routeLocationProvider))
    ..onLifecycleChanged(ref.read(appLifecycleProvider));

  // Listen to changes afterwards
  ref
    ..listen<bool>(
      splashProvider,
      (_, bool next) {
        service.onSplashCompleted(splashCompleted: next);
      },
    )
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      (_, AsyncValue<AuthState> next) {
        service.onAuthenticated(authenticated: next.valueOrNull?.isAuthenticated ?? false);
      },
    )
    ..listen<String?>(
      currentPubkeySelectorProvider,
      (_, String? next) {
        service.onMasterPubkey(next);
      },
    )
    ..listen<AsyncValue<UserMetadataEntity?>>(
      currentUserMetadataProvider,
      (_, AsyncValue<UserMetadataEntity?> next) {
        service.onUserMetadata(next.valueOrNull);
      },
    )
    ..listen<AsyncValue<bool>>(
      delegationCompleteProvider,
      (_, AsyncValue<bool> next) {
        service.onDelegationComplete(delegationComplete: next.valueOrNull.falseOrValue);
      },
    )
    ..listen<AsyncValue<bool>>(
      isCurrentUserSecuredProvider,
      (_, AsyncValue<bool> next) {
        final value = next.valueOrNull;
        if (value != null) {
          service.onSecured(secured: value);
        }
      },
    )
    ..listen<String>(
      routeLocationProvider,
      (_, String next) {
        service.onRouteChanged(next);
      },
    )
    ..listen<AppLifecycleState>(
      appLifecycleProvider,
      (_, AppLifecycleState next) {
        service.onLifecycleChanged(next);
      },
    );

  return service;
}
