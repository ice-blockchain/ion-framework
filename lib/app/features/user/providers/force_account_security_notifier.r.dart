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
import 'package:ion/app/features/protect_account/secure_account/providers/recovery_credentials_enabled_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/security_account_provider.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/user_details_provider.r.dart';
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
    required Duration enforceDelay,
    required void Function() emitDialog,
  })  : _enforceDelay = enforceDelay,
        _emitDialog = emitDialog;

  UserMetadataEntity? _metadata;
  bool _secured = true;
  String _route = '';
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  final Duration _enforceDelay;
  final void Function() _emitDialog;

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _metadata = null;
    _secured = true;
    _route = '';
    _lifecycle = AppLifecycleState.resumed;
    _timer?.cancel();
    _timer = null;
  }

  void onUserMetadata(UserMetadataEntity? value) {
    _metadata = value;
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
    if (rootNavigatorKey.currentContext == null) return;

    if (_metadata == null) return;
    final metadata = _metadata!;

    if (_secured) return;

    if (_lifecycle != AppLifecycleState.resumed) return;

    if (_route != FeedRoute().location) return;

    final now = DateTime.now();
    final enforceTime = (metadata.data.registeredAt?.toDateTime ?? now).add(_enforceDelay);
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

    _emitDialog();
  }
}

@Riverpod(keepAlive: true)
ForceAccountSecurityService forceAccountSecurityService(Ref ref) {
  final service = ForceAccountSecurityService(
    enforceDelay: ref.read(envProvider.notifier).get<Duration>(
          EnvVariable.ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES,
        ),
    emitDialog: () {
      ref.read(uiEventQueueNotifierProvider.notifier).emit(const SecureAccountDialogEvent());
    },
  );

  var splashCompleted = false;
  var isAuthenticated = false;
  String? masterPubkey;
  var delegationComplete = false;
  var secondaryListenersRegistered = false;

  ProviderSubscription<AsyncValue<UserMetadataEntity?>>? userMetadataSub;
  ProviderSubscription<AsyncValue<bool>>? isSecuredSub;
  ProviderSubscription<String>? routeSub;
  ProviderSubscription<AppLifecycleState>? lifecycleSub;

  var lastIsAuthenticated = false;

  bool canStart() =>
      splashCompleted && isAuthenticated && masterPubkey != null && delegationComplete;

  void registerSecondaryListeners() {
    if (secondaryListenersRegistered || !canStart()) {
      return;
    }
    secondaryListenersRegistered = true;

    userMetadataSub = ref.listen<AsyncValue<UserMetadataEntity?>>(
      currentUserMetadataProvider,
      fireImmediately: true,
      (_, AsyncValue<UserMetadataEntity?> next) {
        service.onUserMetadata(next.valueOrNull);
      },
    );

    isSecuredSub = ref.listen<AsyncValue<bool>>(
      isCurrentUserSecuredProvider,
      fireImmediately: true,
      (_, AsyncValue<bool> next) {
        final value = next.valueOrNull;
        if (value != null) {
          service.onSecured(secured: value);
        }
      },
    );

    routeSub = ref.listen<String>(
      routeLocationProvider,
      fireImmediately: true,
      (_, String next) {
        service.onRouteChanged(next);
      },
    );

    lifecycleSub = ref.listen<AppLifecycleState>(
      appLifecycleProvider,
      fireImmediately: true,
      (_, AppLifecycleState next) {
        service.onLifecycleChanged(next);
        if (next == AppLifecycleState.resumed) {
          ref
            ..invalidate(userDetailsProvider)
            ..invalidate(recoveryCredentialsEnabledProvider);
        }
      },
    );
  }

  ref
    ..onDispose(service.dispose)
    ..listen<bool>(
      splashProvider,
      fireImmediately: true,
      (_, bool next) {
        splashCompleted = next;
        registerSecondaryListeners();
      },
    )
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      fireImmediately: true,
      (_, AsyncValue<AuthState> next) {
        final authenticated = next.valueOrNull?.isAuthenticated ?? false;

        // detect logout: was authenticated, now not
        if (lastIsAuthenticated && !authenticated) {
          secondaryListenersRegistered = false;

          userMetadataSub?.close();
          userMetadataSub = null;

          isSecuredSub?.close();
          isSecuredSub = null;

          routeSub?.close();
          routeSub = null;

          lifecycleSub?.close();
          lifecycleSub = null;

          service.reset();

          isAuthenticated = false;
          masterPubkey = null;
          delegationComplete = false;
        } else {
          isAuthenticated = authenticated;
          registerSecondaryListeners();
        }

        lastIsAuthenticated = authenticated;
      },
    )
    ..listen<String?>(
      currentPubkeySelectorProvider,
      fireImmediately: true,
      (_, String? next) {
        masterPubkey = next;
        registerSecondaryListeners();
      },
    )
    ..listen<AsyncValue<bool>>(
      delegationCompleteProvider,
      fireImmediately: true,
      (_, AsyncValue<bool> next) {
        delegationComplete = next.valueOrNull.falseOrValue;
        registerSecondaryListeners();
      },
    );

  return service;
}
