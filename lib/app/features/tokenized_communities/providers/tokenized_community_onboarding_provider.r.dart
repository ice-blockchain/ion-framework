// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/tokenized_community_onboarding_dialog/tokenized_community_onboarding_dialog.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tokenized_community_onboarding_provider.r.g.dart';

class TokenizedCommunityOnboardingService {
  TokenizedCommunityOnboardingService({
    required void Function() emitDialog,
    required Future<void> Function() setShown,
  })  : _emitDialog = emitDialog,
        _setShown = setShown;

  bool? _authenticated;
  bool? _delegationCompleted;
  bool? _userHasBscWallet;
  bool? _alreadyShown;
  String? _route;

  final void Function() _emitDialog;
  final Future<void> Function() _setShown;

  void onAuthenticated({required bool? authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  void onDelegationCompleted({required bool? delegationCompleted}) {
    _delegationCompleted = delegationCompleted;
    _maybeTrigger();
  }

  void onUserHasBscWalletChanged({required bool hasBscWallet}) {
    _userHasBscWallet = hasBscWallet;
    _maybeTrigger();
  }

  void onRouteChanged(String value) {
    _route = value;
    _maybeTrigger();
  }

  void onShownChanged({required bool? shown}) {
    _alreadyShown = shown;
    _maybeTrigger();
  }

  Future<void> _maybeTrigger() async {
    if (_authenticated != true) return;
    if (_delegationCompleted != true) return;
    if (_userHasBscWallet != true) return;
    if (_alreadyShown ?? true) return;
    if (_route != FeedRoute().location) return;

    _emitDialog();
    await _setShown();
  }
}

@riverpod
TokenizedCommunityOnboardingService? tokenizedCommunityOnboardingService(Ref ref) {
  final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);

  if (userPreferencesService == null) return null;

  final service = TokenizedCommunityOnboardingService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const TokenizedCommunityOnboardingDialogEvent());
    },
    setShown: () async {
      await ref.read(tokenizedCommunityOnboardingShownProvider.notifier).setShown();
    },
  );

  ref
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      fireImmediately: true,
      (_, next) {
        service.onAuthenticated(authenticated: next.valueOrNull?.isAuthenticated);
      },
    )
    ..listen<AsyncValue<bool?>>(
      delegationCompleteProvider,
      fireImmediately: true,
      (_, next) {
        service.onDelegationCompleted(delegationCompleted: next.valueOrNull);
      },
    )
    ..listen<String>(
      routeLocationProvider,
      fireImmediately: true,
      (_, next) {
        service.onRouteChanged(next);
      },
    )
    ..listen<AsyncValue<BscWalletCheckResult>>(
      bscWalletCheckProvider,
      fireImmediately: true,
      (_, next) {
        if (!next.isLoading && next.hasValue) {
          service.onUserHasBscWalletChanged(hasBscWallet: next.value!.hasBscWallet);
        }
      },
    )
    ..listen<bool?>(
      tokenizedCommunityOnboardingShownProvider,
      fireImmediately: true,
      (_, next) {
        service.onShownChanged(shown: next);
      },
    );

  return service;
}

@riverpod
class TokenizedCommunityOnboardingShown extends _$TokenizedCommunityOnboardingShown {
  static const String _key = 'tokenized_community_onboarding_shown';

  @override
  bool? build() {
    final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return null;
    }
    return userPreferencesService.getValue<bool>(_key) ?? false;
  }

  Future<void> setShown() async {
    final userPreferencesService = ref.read(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return;
    }
    await userPreferencesService.setValue(_key, true);
    state = true;
  }
}
