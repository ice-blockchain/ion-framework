// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/protect_account/authenticator/data/adapter/twofa_type_adapter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_action_notifier.r.g.dart';

@riverpod
class LoginActionNotifier extends _$LoginActionNotifier {
  Completer<void>? _autoPasskeyLoginCompleter;

  @override
  FutureOr<void> build() {}

  void cancelAutoPasskeyLogin() {
    final completer = _autoPasskeyLoginCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _autoPasskeyLoginCompleter = null;
  }

  Future<void> verifyUserLoginFlow({required String keyName}) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      await ionIdentity(username: keyName).auth.verifyUserLoginFlow();
    });
  }

  Future<void> signIn({
    required String keyName,
    required AuthConfig config,
    required bool localCredsOnly,
    Map<TwoFaType, String>? twoFaTypes,
  }) async {
    state = const AsyncValue.loading();

    final isAutoPasskey = keyName.isEmpty && localCredsOnly;
    Completer<void>? cancelCompleter;
    if (isAutoPasskey) {
      final completer = _autoPasskeyLoginCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
      cancelCompleter = Completer<void>();
      _autoPasskeyLoginCompleter = cancelCompleter;
    }

    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final twoFATypes = [
        for (final entry in (twoFaTypes ?? {}).entries)
          TwoFaTypeAdapter(entry.key, entry.value).twoFAType,
      ];

      try {
        await ionIdentity(username: keyName).auth.login(
              config: config,
              twoFATypes: twoFATypes,
              localCredsOnly: localCredsOnly,
              cancel: cancelCompleter?.future,
            );
      } on NoLocalPasskeyCredsFoundIONIdentityException {
        // Are we trying to suggest a passkey for empty identity key name?
        // If yes, and there're no local creds, do nothing
        // If no, rethrow
        if (keyName.isNotEmpty) {
          rethrow;
        }
      } on SignInCancelException {
        return;
      } finally {
        if (identical(_autoPasskeyLoginCompleter, cancelCompleter)) {
          _autoPasskeyLoginCompleter = null;
        }
      }
    });
  }
}
