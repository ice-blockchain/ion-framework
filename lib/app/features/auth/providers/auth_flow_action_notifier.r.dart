// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/early_access_provider.r.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/sentry/api_error_sentry_logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_flow_action_notifier.r.g.dart';

const _registerFlowSentryTag = 'auth_register_flow';

void _logRegisterError(
  Object error,
  StackTrace stackTrace, {
  required String step,
  required String username,
  required SignUpKind kind,
}) {
  final networkContext = extractApiErrorNetworkContext(error);
  unawaited(
    SentryService.logException(
      error,
      stackTrace: stackTrace,
      tag: _registerFlowSentryTag,
      tags: {
        'step': step,
        'username': username,
        'sign_up_kind': kind.name,
      },
      debugContext: networkContext.isEmpty ? null : networkContext,
    ),
  );
}

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
      final signUpLoginFallbackEnabled = ref
          .read(featureFlagsProvider.notifier)
          .get(AuthFeatureFlag.signUpLoginFallbackOnUserAlreadyExists);

      final authStateBeforeAction = await ref.read(authProvider.future);
      final previouslyAuthenticatedUsers = authStateBeforeAction.authenticatedIdentityKeyNames;

      try {
        switch (kind) {
          case SignUpKind.passkey:
            await ionIdentity(username: keyName).auth.registerUser(earlyAccessEmail);
          case SignUpKind.password:
            await ionIdentity(username: keyName)
                .auth
                .registerUserWithPassword(password ?? '', earlyAccessEmail);
        }

        await ref.read(authProvider.notifier).handleSwitchingToExistingAccount(
              keyName,
              currentAuthenticatedUsers: previouslyAuthenticatedUsers,
            );
      } on UserAlreadyExistsException {
        if (!signUpLoginFallbackEnabled) {
          rethrow;
        }

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

        await ref.read(authProvider.notifier).handleSwitchingToExistingAccount(
              keyName,
              currentAuthenticatedUsers: previouslyAuthenticatedUsers,
            );
      } on PasskeyCancelledException {
        return;
      } catch (error, stackTrace) {
        _logRegisterError(
          error,
          stackTrace,
          step: 'sign_up_or_login.failed',
          username: keyName,
          kind: kind,
        );
        rethrow;
      }
    });
  }
}

enum SignUpKind { passkey, password }
