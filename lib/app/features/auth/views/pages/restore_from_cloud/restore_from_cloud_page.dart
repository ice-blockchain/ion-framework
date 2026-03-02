// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/components/set_recovery_password_step.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/models/recover_user_step.dart';
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/components/recover_from_cloud_verify_step.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_input_step.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_options_step.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/protect_account/backup/providers/recover_user_action_notifier.m.dart';
import 'package:ion/app/features/protect_account/backup/providers/recovery_key_cloud_backup_delete_notifier.r.dart';
import 'package:ion/app/features/protect_account/backup/providers/recovery_key_cloud_backup_restore_notifier.r.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class RestoreFromCloudPage extends HookConsumerWidget {
  const RestoreFromCloudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(RecoverUserStep.recoveryCreds);
    final twoFAOptions = useRef<Map<TwoFaType, String>?>(null);
    final twoFAOptionsCount = useRef<int>(0);
    final recoveryChallengeRef = useRef<UserRegistrationChallenge?>(null);

    ref
      ..displayErrors(
        recoveryKeyCloudBackupRestoreNotifierProvider,
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..displayErrors(completeUserRecoveryActionNotifierProvider);
    _listenInitRecoverResult(
      ref: ref,
      twoFAOptions: twoFAOptions,
      twoFAOptionsCountRef: twoFAOptionsCount,
      step: step,
      recoveryChallengeRef: recoveryChallengeRef,
    );
    _listenCompleteRecoverResult(ref, step: step, recoveryChallengeRef: recoveryChallengeRef);

    return switch (step.value) {
      RecoverUserStep.recoveryCreds => RestoreFromCloudVerifyStep(
          onContinue: (identityKeyName, password) {
            _restoreKey(context, ref, identityKeyName: identityKeyName, password: password);
          },
          isLoading: ref.watch(
                recoveryKeyCloudBackupRestoreNotifierProvider.select((it) => it.isLoading),
              ) ||
              ref.watch(initUserRecoveryActionNotifierProvider.select((it) => it.isLoading)) ||
              ref.watch(completeUserRecoveryActionNotifierProvider.select((it) => it.isLoading)),
        ),
      RecoverUserStep.twoFAOptions => ProviderScope(
          overrides: [
            availableTwoFaTypesProvider.overrideWithValue(
              (types: TwoFaType.values, count: twoFAOptionsCount.value),
            ),
          ],
          child: TwoFAOptionsStep(
            twoFAOptionsCount: twoFAOptionsCount.value,
            onConfirm: () => step.value = RecoverUserStep.twoFAInput,
            onBackPress: () => step.value = RecoverUserStep.recoveryCreds,
            titleIcon: Assets.svg.iconLoginRestorecloud.icon(size: 36.0.s),
          ),
        ),
      RecoverUserStep.twoFAInput => ProviderScope(
          overrides: [
            availableTwoFaTypesProvider.overrideWithValue(
              (types: TwoFaType.values, count: twoFAOptionsCount.value),
            ),
          ],
          child: TwoFAInputStep(
            identityKeyName: ref.watch(
              recoveryKeyCloudBackupRestoreNotifierProvider.select(
                (state) => state.valueOrNull?.identityKeyName,
              ),
            )!,
            onContinuePressed: (twoFaTypes) {
              twoFAOptions.value = twoFaTypes;
              _makeRecoverUserRequest(ref, twoFaTypes);
            },
            onBackPress: () => step.value = RecoverUserStep.twoFAOptions,
            isLoading: ref.watch(
                  initUserRecoveryActionNotifierProvider.select((it) => it.isLoading),
                ) ||
                ref.watch(completeUserRecoveryActionNotifierProvider.select((it) => it.isLoading)),
            titleIcon: Assets.svg.iconLoginRestorecloud.icon(size: 36.0.s),
          ),
        ),
      RecoverUserStep.setNewPassword => SetRecoveryPasswordStep(
          identityKeyName: ref.watch(
            recoveryKeyCloudBackupRestoreNotifierProvider.select(
              (state) => state.valueOrNull?.identityKeyName,
            ),
          )!,
          onBackPress: () {
            step.value = twoFAOptionsCount.value > 0
                ? RecoverUserStep.twoFAInput
                : RecoverUserStep.recoveryCreds;
          },
          isLoading:
              ref.watch(completeUserRecoveryActionNotifierProvider.select((it) => it.isLoading)),
          onContinue: (newPassword) => _completeRecoveryWithPassword(
            ref,
            newPassword: newPassword,
            recoveryChallengeRef: recoveryChallengeRef,
          ),
        ),
    };
  }

  Future<void> _completeRecoveryWithPassword(
    WidgetRef ref, {
    required String newPassword,
    required ObjectRef<UserRegistrationChallenge?> recoveryChallengeRef,
  }) async {
    final challenge = recoveryChallengeRef.value;
    if (challenge == null) return;
    final recoveryCredentials = ref.read(recoveryKeyCloudBackupRestoreNotifierProvider).valueOrNull;
    if (recoveryCredentials == null) return;
    await ref
        .read(completeUserRecoveryActionNotifierProvider.notifier)
        .completeRecoveryWithPassword(
          username: recoveryCredentials.identityKeyName,
          credentialId: recoveryCredentials.recoveryKeyId,
          recoveryKey: recoveryCredentials.recoveryCode,
          challenge: challenge,
          newPassword: newPassword,
        );
  }

  Future<void> _restoreKey(
    BuildContext context,
    WidgetRef ref, {
    required String identityKeyName,
    required String password,
  }) async {
    await ref
        .watch(recoveryKeyCloudBackupRestoreNotifierProvider.notifier)
        .restore(identityKeyName: identityKeyName, password: password);
    final recoveryCredentialsProvider = ref.read(recoveryKeyCloudBackupRestoreNotifierProvider);
    if (!recoveryCredentialsProvider.hasError && recoveryCredentialsProvider.valueOrNull == null) {
      throw Exception('No credentials');
    } else if (recoveryCredentialsProvider.hasValue) {
      _makeRecoverUserRequest(ref);
    }
  }

  void _makeRecoverUserRequest(
    WidgetRef ref, [
    Map<TwoFaType, String>? twoFaTypes,
  ]) {
    final recoveryCredentials = ref.read(recoveryKeyCloudBackupRestoreNotifierProvider).valueOrNull;
    ref.read(initUserRecoveryActionNotifierProvider.notifier).initRecovery(
          username: recoveryCredentials!.identityKeyName,
          credentialId: recoveryCredentials.recoveryKeyId,
          twoFaTypes: twoFaTypes,
        );
  }

  void _listenInitRecoverResult({
    required WidgetRef ref,
    required ObjectRef<Map<TwoFaType, String>?> twoFAOptions,
    required ObjectRef<int> twoFAOptionsCountRef,
    required ValueNotifier<RecoverUserStep> step,
    required ObjectRef<UserRegistrationChallenge?> recoveryChallengeRef,
  }) {
    ref
      ..listenError(initUserRecoveryActionNotifierProvider, (error) {
        if (error is TwoFARequiredException) {
          twoFAOptionsCountRef.value = error.twoFAOptionsCount;
          step.value = RecoverUserStep.twoFAOptions;
        }
      })
      ..displayErrors(
        initUserRecoveryActionNotifierProvider,
        excludedExceptions: {
          TwoFARequiredException,
          ...excludedPasskeyExceptions,
        },
      )
      ..listenSuccess(initUserRecoveryActionNotifierProvider, (value) async {
        final challenge = value?.whenOrNull(success: (challenge) => challenge);
        if (challenge == null) return;

        recoveryChallengeRef.value = challenge;
        final isPasskeyAvailable = ref.read(isPasskeyAvailableProvider).valueOrNull ?? false;

        if (!isPasskeyAvailable) {
          step.value = RecoverUserStep.setNewPassword;
          return;
        }

        await guardPasskeyDialog(
          ref.context,
          (child) => RiverpodVerifyIdentityRequestBuilder(
            provider: completeUserRecoveryActionNotifierProvider,
            requestWithVerifyIdentity: (_) {
              final recoveryCredentials =
                  ref.read(recoveryKeyCloudBackupRestoreNotifierProvider).valueOrNull;
              ref.read(completeUserRecoveryActionNotifierProvider.notifier).completeRecovery(
                    username: recoveryCredentials!.identityKeyName,
                    credentialId: recoveryCredentials.recoveryKeyId,
                    recoveryKey: recoveryCredentials.recoveryCode,
                    challenge: challenge,
                  );
            },
            child: child,
          ),
        );

        if (!ref.context.mounted) return;
        final completeState = ref.read(completeUserRecoveryActionNotifierProvider);
        final isSuccess = completeState.valueOrNull?.whenOrNull(success: () => true) ?? false;
        if (!isSuccess) {
          step.value = RecoverUserStep.setNewPassword;
        }
      });
  }

  void _listenCompleteRecoverResult(
    WidgetRef ref, {
    required ValueNotifier<RecoverUserStep> step,
    required ObjectRef<UserRegistrationChallenge?> recoveryChallengeRef,
  }) {
    ref.listenSuccess(
      completeUserRecoveryActionNotifierProvider,
      (value) {
        value?.whenOrNull(
          success: () async {
            final recoveryCredentials =
                ref.read(recoveryKeyCloudBackupRestoreNotifierProvider).valueOrNull;
            if (recoveryCredentials == null) return;
            final wasPasskeyCompletion = step.value != RecoverUserStep.setNewPassword;
            if (wasPasskeyCompletion) {
              final ionIdentity = await ref.read(ionIdentityProvider.future);
              await ionIdentity(username: recoveryCredentials.identityKeyName)
                  .auth
                  .clearPasswordUserState();
            }
            await ref
                .read(recoveryKeyCloudBackupDeleteNotifierProvider.notifier)
                .remove(identityKeyName: recoveryCredentials.identityKeyName);
            if (ref.context.mounted) {
              await RecoverUserSuccessRoute().push<void>(ref.context);
            }
          },
        );
      },
    );
  }
}
