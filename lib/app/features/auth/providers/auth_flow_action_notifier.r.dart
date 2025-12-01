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

      try {
        switch (kind) {
          case SignUpKind.passkey:
            await ionIdentity(username: keyName).auth.registerUser(earlyAccessEmail);
          case SignUpKind.password:
            await ionIdentity(username: keyName)
                .auth
                .registerUserWithPassword(password ?? '', earlyAccessEmail);
        }

        await ref.read(authProvider.notifier).handleSwitchingToExistingAccount(keyName);
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

        await ref.read(authProvider.notifier).handleSwitchingToExistingAccount(keyName);
      } on PasskeyCancelledException {
        return;
      }
    });
  }
}

enum SignUpKind { passkey, password }
