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
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'bsc_wallet_check_service.r.g.dart';

class BscWalletCheckService {
  BscWalletCheckService({
    required void Function() emitDialog,
    required Future<BscWalletCheckResult> Function() checkWallet,
    required UserPreferencesService? userPreferencesService,
  })  : _emitDialog = emitDialog,
        _checkWallet = checkWallet,
        _userPreferencesService = userPreferencesService;

  static const _shownKey = 'required_bsc_wallet_dialog_bootstrap_shown_v1';

  bool _authenticated = false;
  bool? _onboardingComplete;
  bool _splashCompleted = false;
  bool? _currentUserHasToken;
  final _lock = Lock();

  final void Function() _emitDialog;
  final Future<BscWalletCheckResult> Function() _checkWallet;

  UserPreferencesService? _userPreferencesService;

  void onSplashCompleted({required bool splashCompleted}) {
    _splashCompleted = splashCompleted;
    _maybeTrigger();
  }

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  // ignore: avoid_positional_boolean_parameters
  void onOnboardingComplete(bool? onboardingComplete) {
    _onboardingComplete = onboardingComplete;
    _maybeTrigger();
  }

  void onUserMetadataChanged() {
    _maybeTrigger();
  }

  void onCurrentUserHasTokenChanged({required bool? hasToken}) {
    _currentUserHasToken = hasToken;
    _maybeTrigger();
  }

  void onUserPreferencesServiceChanged(UserPreferencesService? service) {
    _userPreferencesService = service;
    _maybeTrigger();
  }

  Future<void> _maybeTrigger() async {
    return _lock.synchronized(() async {
      if (!_splashCompleted) return;
      if (!_authenticated) return;
      if (_onboardingComplete != true) return;
      if (_currentUserHasToken == null || (_currentUserHasToken ?? false)) return;
      final prefs = _userPreferencesService;
      if (prefs == null) return;

      try {
        final alreadyShownForUser = prefs.getValue<bool>(_shownKey) ?? false;
        final bscWalletCheckResult = await _checkWallet();
        // We show at least once for every user even if already has BSC wallet
        // it is just for user who hasn't yet the BSC wallet flow will be different for this pop up
        if (!alreadyShownForUser || !bscWalletCheckResult.hasBscWallet) {
          _emitDialog();
          await prefs.setValue(_shownKey, true);
          return;
        }
      } catch (e) {
        Logger.log('Failed to check BSC wallet', error: e.toString());
      }
    });
  }
}

@Riverpod(keepAlive: true)
BscWalletCheckService bscWalletCheckService(Ref ref) {
  final service = BscWalletCheckService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const CreatorMonetizationIsLiveDialogEvent());
    },
    checkWallet: () => ref.read(bscWalletCheckProvider.future),
    userPreferencesService: ref.read(currentUserPreferencesServiceProvider),
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
    ..listen<UserPreferencesService?>(
      currentUserPreferencesServiceProvider,
      fireImmediately: true,
      (_, UserPreferencesService? next) {
        service.onUserPreferencesServiceChanged(next);
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
