// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/early_access_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_flow_action_notifier.r.g.dart';

@riverpod
class AuthFlowActionNotifier extends _$AuthFlowActionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signUpOrLogin({
    required String keyName,
    required AuthConfig config,
    required SignUpKind kind,
    String? password,
  }) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(() async {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final earlyAccessEmail = ref.read(earlyAccessEmailProvider);

      var isNewRegistration = false;
      try {
        switch (kind) {
          case SignUpKind.passkey:
            await ionIdentity(username: keyName).auth.registerUser(earlyAccessEmail);
            isNewRegistration = true;
          case SignUpKind.password:
            await ionIdentity(username: keyName)
                .auth
                .registerUserWithPassword(password ?? '', earlyAccessEmail);
            isNewRegistration = true;
        }
      } on UserAlreadyExistsException {
        try {
          await ionIdentity(username: keyName).auth.verifyUserLoginFlow();
        } catch (_) {}

        // Prefer passkey if available locally, else fall back to password/biometrics
        try {
          await ionIdentity(username: keyName).auth.login(
                config: config,
                twoFATypes: const <TwoFAType>[],
                localCredsOnly: true,
              );
        } on PasskeyNotAvailableException {
          await ionIdentity(username: keyName).auth.login(
                config: config,
                twoFATypes: const <TwoFAType>[],
                localCredsOnly: false,
              );
        }
      } on PasskeyCancelledException {
        return;
      }

      // For new registrations, wait for auth state to update
      if (isNewRegistration) {
        await _waitForAuthComplete(keyName);
      }
    });
  }

  /// Waits for authProvider to confirm the user is fully authenticated
  /// Uses the auth stream to detect when authentication completes naturally
  Future<void> _waitForAuthComplete(String keyName) async {
    final completer = Completer<void>();
    Timer? timeout;

    timeout = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    // Listen to auth stream for authentication completion
    final subscription = ref.listen(
      authProvider,
      (previous, next) {
        final authState = next.valueOrNull;
        if (authState != null &&
            authState.authenticatedIdentityKeyNames.contains(keyName) &&
            authState.hasEventSigner &&
            authState.isAuthenticated) {
          timeout?.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
      fireImmediately: true,
    );

    await completer.future;
    subscription.close();
  }
}

enum SignUpKind { passkey, password }
