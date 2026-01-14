// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/tokenized_community_onboarding_dialog/tokenized_community_onboarding_dialog.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'tokenized_community_onboarding_provider.r.g.dart';

class TokenizedCommunityOnboardingService {
  TokenizedCommunityOnboardingService({
    required void Function() emitDialog,
    required UserPreferencesService userPreferencesService,
  })  : _emitDialog = emitDialog,
        _userPreferencesService = userPreferencesService;

  static const _shownKey = 'tokenized_community_onboarding_shown';

  bool _authenticated = false;
  bool _delegationCompleted = false;
  String? _route;
  final _lock = Lock();

  final void Function() _emitDialog;

  final UserPreferencesService _userPreferencesService;

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  void onDelegationCompleted({required bool delegationCompleted}) {
    _delegationCompleted = delegationCompleted;
    _maybeTrigger();
  }

  void onRouteChanged(String value) {
    _route = value;
    _maybeTrigger();
  }

  Future<void> _maybeTrigger() async {
    return _lock.synchronized(() async {
      if (!_authenticated) return;
      if (!_delegationCompleted) return;
      if (_route != FeedRoute().location) return;

      try {
        final alreadyShownForUser = _userPreferencesService.getValue<bool>(_shownKey) ?? false;
        if (!alreadyShownForUser) {
          _emitDialog();
          //TODO:uncomment
          // await prefs.setValue(_shownKey, true);
          return;
        }
      } catch (error, stackTrace) {
        Logger.error(
          error,
          message: 'Failed to show tokenized community onboarding',
          stackTrace: stackTrace,
        );
      }
    });
  }
}

@Riverpod(keepAlive: true)
TokenizedCommunityOnboardingService? tokenizedCommunityOnboardingService(Ref ref) {
  final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);

  if (userPreferencesService == null) return null;

  final service = TokenizedCommunityOnboardingService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const TokenizedCommunityOnboardingDialogEvent());
    },
    userPreferencesService: userPreferencesService,
  );

  ref
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      fireImmediately: true,
      (_, AsyncValue<AuthState> next) {
        service.onAuthenticated(authenticated: next.valueOrNull?.isAuthenticated ?? false);
      },
    )
    ..listen<AsyncValue<bool?>>(
      delegationCompleteProvider,
      fireImmediately: true,
      (_, AsyncValue<bool?> next) {
        service.onDelegationCompleted(delegationCompleted: next.valueOrNull ?? false);
      },
    )
    ..listen<String>(
      routeLocationProvider,
      fireImmediately: true,
      (_, String next) {
        service.onRouteChanged(next);
      },
    );

  return service;
}
