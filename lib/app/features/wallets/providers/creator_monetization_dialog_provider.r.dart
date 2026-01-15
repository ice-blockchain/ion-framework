// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/auth/views/pages/required_bsc_wallet/creator_monetization_is_live_dialog.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'creator_monetization_dialog_provider.r.g.dart';

class CreatorMonetizationDialogService {
  CreatorMonetizationDialogService({
    required void Function() emitDialog,
    required Future<BscWalletCheckResult> Function() checkWallet,
    required Future<void> Function() setShownForUser,
    required bool alreadyShownForUser,
  })  : _emitDialog = emitDialog,
        _checkWallet = checkWallet,
        _alreadyShownForUser = alreadyShownForUser,
        _setShownForUser = setShownForUser;

  bool _authenticated = false;
  bool? _onboardingComplete;
  bool _splashCompleted = false;
  bool? _currentUserHasToken;
  String _route = '';
  final _lock = Lock();

  final void Function() _emitDialog;
  final Future<BscWalletCheckResult> Function() _checkWallet;
  final Future<void> Function() _setShownForUser;
  final bool _alreadyShownForUser;

  void onSplashCompleted({required bool splashCompleted}) {
    _splashCompleted = splashCompleted;
    _maybeTrigger();
  }

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  // ignore: avoid_positional_boolean_parameters, use_setters_to_change_properties
  void onOnboardingComplete(bool? onboardingComplete) {
    _onboardingComplete = onboardingComplete;
    //no need to call _maybeTrigger as right after onboarding we are showing link device and notifications permission modals
  }

  void onUserMetadataChanged() {
    _maybeTrigger();
  }

  void onCurrentUserHasTokenChanged({required bool? hasToken}) {
    _currentUserHasToken = hasToken;
    _maybeTrigger();
  }

  void onRouteChanged(String value) {
    _route = value;
    _maybeTrigger();
  }

  Future<void> _maybeTrigger() async {
    return _lock.synchronized(() async {
      if (!_splashCompleted) return;
      if (!_authenticated) return;
      if (_onboardingComplete != true) return;
      if (_route != FeedRoute().location) return;
      if (_currentUserHasToken == null || (_currentUserHasToken ?? false)) return;

      try {
        final bscWalletCheckResult = await _checkWallet();
        // We show at least once for every user even if already has BSC wallet
        // it is just for user who hasn't yet the BSC wallet flow will be different for this pop up
        if (!_alreadyShownForUser || !bscWalletCheckResult.hasBscWallet) {
          _emitDialog();
          await _setShownForUser();
          return;
        }
      } catch (e) {
        Logger.log('Failed to check BSC wallet', error: e.toString());
      }
    });
  }
}

@Riverpod(keepAlive: true)
CreatorMonetizationDialogService creatorMonetizationDialogService(Ref ref) {
  final service = CreatorMonetizationDialogService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const CreatorMonetizationIsLiveDialogEvent());
    },
    checkWallet: () => ref.read(bscWalletCheckProvider.future),
    alreadyShownForUser: ref.watch(creatorMonetizationIsLiveDialogShownProvider),
    setShownForUser: () =>
        ref.read(creatorMonetizationIsLiveDialogShownProvider.notifier).setShown(),
  );

  ref
    ..listen<bool>(
      splashProvider,
      fireImmediately: true,
      (_, bool next) {
        service.onSplashCompleted(splashCompleted: next);
      },
    )
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      fireImmediately: true,
      (_, AsyncValue<AuthState> next) {
        service.onAuthenticated(authenticated: next.valueOrNull?.isAuthenticated ?? false);
      },
    )
    ..listen<AsyncValue<bool?>>(
      onboardingCompleteProvider,
      fireImmediately: true,
      (_, AsyncValue<bool?> next) {
        service.onOnboardingComplete(next.valueOrNull);
      },
    )
    ..listen<String>(
      routeLocationProvider,
      fireImmediately: true,
      (_, String next) {
        service.onRouteChanged(next);
      },
    )
    ..listen<AsyncValue<bool?>>(
      currentUserHasTokenProvider,
      fireImmediately: true,
      (_, AsyncValue<bool?> next) {
        service.onCurrentUserHasTokenChanged(hasToken: next.valueOrNull);
      },
    )
    ..listen<AsyncValue<UserMetadataEntity?>>(
      currentUserMetadataProvider,
      fireImmediately: true,
      (AsyncValue<UserMetadataEntity?>? prev, AsyncValue<UserMetadataEntity?> next) {
        if (next.hasValue && next.value?.masterPubkey != prev?.value?.masterPubkey) {
          service.onUserMetadataChanged();
        }
      },
    );

  return service;
}

@Riverpod(keepAlive: true)
class CreatorMonetizationIsLiveDialogShown extends _$CreatorMonetizationIsLiveDialogShown {
  static const String _key = 'creator_monetization_is_live_dialog_shown';

  @override
  bool build() {
    final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return false;
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
