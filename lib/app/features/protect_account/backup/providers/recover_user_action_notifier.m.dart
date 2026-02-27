// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/protect_account/authenticator/data/adapter/twofa_type_adapter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recover_user_action_notifier.m.freezed.dart';
part 'recover_user_action_notifier.m.g.dart';

const _recoveryFlowSentryTag = 'auth_recovery_flow';

void _logRecoveryStep(String step, {required String username}) {
  unawaited(
    SentryService.logMessage(
      step,
      tag: _recoveryFlowSentryTag,
      tags: {
        'username': username,
      },
    ),
  );
}

void _logRecoveryError(
  Object error,
  StackTrace stackTrace, {
  required String step,
  required String username,
}) {
  unawaited(
    SentryService.logException(
      error,
      stackTrace: stackTrace,
      tag: _recoveryFlowSentryTag,
      tags: {
        'step': step,
        'username': username,
      },
    ),
  );
}

@freezed
class InitUserRecoveryActionState with _$InitUserRecoveryActionState {
  const factory InitUserRecoveryActionState.initial() = _InitUserRecoveryActionStateInitial;

  const factory InitUserRecoveryActionState.success(UserRegistrationChallenge challenge) =
      _InitUserRecoveryActionStateSuccess;
}

@freezed
class CompleteUserRecoveryActionState with _$CompleteUserRecoveryActionState {
  const factory CompleteUserRecoveryActionState.initial() = _CompleteUserRecoveryActionStateInitial;

  const factory CompleteUserRecoveryActionState.success() = _CompleteUserRecoveryActionStateSuccess;
}

@riverpod
class InitUserRecoveryActionNotifier extends _$InitUserRecoveryActionNotifier {
  @override
  FutureOr<InitUserRecoveryActionState> build() => const InitUserRecoveryActionState.initial();

  Future<void> initRecovery({
    required String username,
    required String credentialId,
    Map<TwoFaType, String>? twoFaTypes,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      _logRecoveryStep('init_recovery.start', username: username);
      final ionIdentity = await ref.read(ionIdentityProvider.future);

      final twoFATypes = [
        for (final entry in (twoFaTypes ?? {}).entries)
          TwoFaTypeAdapter(entry.key, entry.value).twoFAType,
      ];

      try {
        final challenge = await ionIdentity(username: username).auth.initRecovery(
              credentialId: credentialId,
              twoFATypes: twoFATypes,
            );
        _logRecoveryStep('init_recovery.success', username: username);
        return InitUserRecoveryActionState.success(challenge);
      } on PasskeyCancelledException {
        _logRecoveryStep('init_recovery.cancelled', username: username);
        return const InitUserRecoveryActionState.initial();
      } catch (error, stackTrace) {
        _logRecoveryError(
          error,
          stackTrace,
          step: 'init_recovery.failed',
          username: username,
        );
        rethrow;
      }
    });
  }
}

@riverpod
class CompleteUserRecoveryActionNotifier extends _$CompleteUserRecoveryActionNotifier {
  @override
  FutureOr<CompleteUserRecoveryActionState> build() =>
      const CompleteUserRecoveryActionState.initial();

  Future<void> completeRecovery({
    required String username,
    required String credentialId,
    required String recoveryKey,
    required UserRegistrationChallenge challenge,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      _logRecoveryStep('complete_recovery.start', username: username);
      final ionIdentity = await ref.read(ionIdentityProvider.future);

      try {
        await ionIdentity(username: username).auth.completeRecovery(
              challenge: challenge,
              credentialId: credentialId,
              recoveryKey: recoveryKey,
            );
      } on PasskeyCancelledException {
        _logRecoveryStep('complete_recovery.cancelled', username: username);
        rethrow;
      } catch (error, stackTrace) {
        _logRecoveryError(
          error,
          stackTrace,
          step: 'complete_recovery.failed',
          username: username,
        );
        rethrow;
      }

      _logRecoveryStep('complete_recovery.success', username: username);

      return const CompleteUserRecoveryActionState.success();
    });
  }

  Future<void> completeRecoveryWithPassword({
    required String username,
    required String credentialId,
    required String recoveryKey,
    required UserRegistrationChallenge challenge,
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      _logRecoveryStep('complete_recovery_with_password.start', username: username);
      final ionIdentity = await ref.read(ionIdentityProvider.future);

      try {
        await ionIdentity(username: username).auth.completeRecoveryWithPassword(
              challenge: challenge,
              credentialId: credentialId,
              recoveryKey: recoveryKey,
              newPassword: newPassword,
            );
      } catch (error, stackTrace) {
        _logRecoveryError(
          error,
          stackTrace,
          step: 'complete_recovery_with_password.failed',
          username: username,
        );
        rethrow;
      }

      _logRecoveryStep('complete_recovery_with_password.success', username: username);

      return const CompleteUserRecoveryActionState.success();
    });
  }
}
