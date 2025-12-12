// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_provider.r.dart';
import 'package:ion/app/features/auth/views/pages/required_bsc_wallet/required_bsc_wallet_dialog.dart';
import 'package:ion/app/features/core/providers/splash_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'bsc_wallet_check_service.r.g.dart';

class BscWalletCheckService {
  BscWalletCheckService({
    required void Function() emitDialog,
    required Future<BscWalletCheckResult> Function() checkWallet,
  })  : _emitDialog = emitDialog,
        _checkWallet = checkWallet;

  bool _authenticated = false;
  bool? _onboardingComplete;
  bool _splashCompleted = false;
  bool _dialogShown = false;
  final _lock = Lock();

  final void Function() _emitDialog;
  final Future<BscWalletCheckResult> Function() _checkWallet;

  void onSplashCompleted({required bool splashCompleted}) {
    _splashCompleted = splashCompleted;
    _maybeTrigger();
  }

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _resetDialogFlagIfNeeded(shouldReset: !authenticated);
    _maybeTrigger();
  }

  // ignore: avoid_positional_boolean_parameters
  void onOnboardingComplete(bool? onboardingComplete) {
    _onboardingComplete = onboardingComplete;
    _resetDialogFlagIfNeeded(shouldReset: onboardingComplete != true);
    _maybeTrigger();
  }

  void onUserMetadataChanged() {
    _resetDialogFlagIfNeeded(shouldReset: true);
    _maybeTrigger();
  }

  void _resetDialogFlagIfNeeded({required bool shouldReset}) {
    if (shouldReset) {
      _dialogShown = false;
    }
  }

  Future<void> _maybeTrigger() async {
    return _lock.synchronized(() async {
      if (!_splashCompleted) return;
      if (!_authenticated) return;
      if (_onboardingComplete != true) return;
      if (_dialogShown) return;

      try {
        final bscWalletCheckResult = await _checkWallet();

        if (!_dialogShown && !bscWalletCheckResult.hasBscWallet) {
          _dialogShown = true;
          _emitDialog();
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
          .emit(const ShowRequiredBscWalletDialogEvent());
    },
    checkWallet: () => ref.read(bscWalletCheckProvider.future),
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
    ..listen<AsyncValue<UserMetadataEntity?>>(
      currentUserMetadataProvider,
      fireImmediately: true,
      (_, AsyncValue<UserMetadataEntity?> next) {
        if (next.hasValue) {
          service.onUserMetadataChanged();
        }
      },
    );

  return service;
}
