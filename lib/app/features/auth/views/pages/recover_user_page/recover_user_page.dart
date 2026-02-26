// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/components/errors/recover_invalid_credentials_error_alert.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/components/recovery_creds_step.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/components/set_recovery_password_step.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/models/recover_user_step.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_try_again_page.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_input_step.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_options_step.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/protect_account/backup/providers/recover_user_action_notifier.m.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';
import 'package:ion/app/features/user/providers/user_verify_identity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef RecoveryCreds = ({String name, String id, String code});

class RecoverUserPage extends HookConsumerWidget {
  const RecoverUserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(RecoverUserStep.recoveryCreds);
    final recoveryCreds = useRef<RecoveryCreds?>(null);
    final twoFAOptions = useRef<Map<TwoFaType, String>?>(null);
    final twoFAOptionsCount = useRef<int>(0);
    final recoveryChallengeRef = useRef<UserRegistrationChallenge?>(null);

    ref.displayErrors(completeUserRecoveryActionNotifierProvider);
    _listenInitRecoverResult(
      ref: ref,
      recoveryCreds: recoveryCreds,
      twoFAOptions: twoFAOptions,
      twoFAOptionsCountRef: twoFAOptionsCount,
      step: step,
      recoveryChallengeRef: recoveryChallengeRef,
    );
    _listenCompleteRecoverResult(ref, step: step, recoveryCreds: recoveryCreds);

    return switch (step.value) {
      RecoverUserStep.recoveryCreds => RecoveryCredsStep(
          onContinuePressed: (name, id, code) {
            recoveryCreds.value = (name: name, id: id, code: code);
            _makeRecoverUserRequest(ref, recoveryCreds.value!);
          },
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
          ),
        ),
      RecoverUserStep.twoFAInput => ProviderScope(
          overrides: [
            availableTwoFaTypesProvider.overrideWithValue(
              (types: TwoFaType.values, count: twoFAOptionsCount.value),
            ),
          ],
          child: TwoFAInputStep(
            identityKeyName: recoveryCreds.value!.name,
            onContinuePressed: (twoFaTypes) {
              twoFAOptions.value = twoFaTypes;
              _makeRecoverUserRequest(ref, recoveryCreds.value!, twoFaTypes);
            },
            onBackPress: () => step.value = RecoverUserStep.twoFAOptions,
            isLoading: ref.watch(
              initUserRecoveryActionNotifierProvider.select((notifier) => notifier.isLoading),
            ),
          ),
        ),
      RecoverUserStep.setNewPassword => SetRecoveryPasswordStep(
          identityKeyName: recoveryCreds.value!.name,
          onBackPress: () {
            step.value = twoFAOptionsCount.value > 0
                ? RecoverUserStep.twoFAInput
                : RecoverUserStep.recoveryCreds;
          },
          isLoading:
              ref.watch(completeUserRecoveryActionNotifierProvider.select((it) => it.isLoading)),
          onContinue: (newPassword) => _completeRecoveryWithPassword(
            ref,
            recoveryCreds: recoveryCreds.value!,
            newPassword: newPassword,
            recoveryChallengeRef: recoveryChallengeRef,
          ),
        ),
    };
  }

  Future<void> _completeRecoveryWithPassword(
    WidgetRef ref, {
    required RecoveryCreds recoveryCreds,
    required String newPassword,
    required ObjectRef<UserRegistrationChallenge?> recoveryChallengeRef,
  }) async {
    final challenge = recoveryChallengeRef.value;
    if (challenge == null) return;
    await ref
        .read(completeUserRecoveryActionNotifierProvider.notifier)
        .completeRecoveryWithPassword(
          username: recoveryCreds.name,
          credentialId: recoveryCreds.id,
          recoveryKey: recoveryCreds.code,
          challenge: challenge,
          newPassword: newPassword,
        );
  }

  void _makeRecoverUserRequest(
    WidgetRef ref,
    RecoveryCreds recoveryCreds, [
    Map<TwoFaType, String>? twoFaTypes,
  ]) {
    ref.read(initUserRecoveryActionNotifierProvider.notifier).initRecovery(
          username: recoveryCreds.name,
          credentialId: recoveryCreds.id,
          twoFaTypes: twoFaTypes,
        );
  }

  void _listenInitRecoverResult({
    required WidgetRef ref,
    required ObjectRef<RecoveryCreds?> recoveryCreds,
    required ObjectRef<Map<TwoFaType, String>?> twoFAOptions,
    required ObjectRef<int> twoFAOptionsCountRef,
    required ValueNotifier<RecoverUserStep> step,
    required ObjectRef<UserRegistrationChallenge?> recoveryChallengeRef,
  }) {
    ref
      ..listenError(initUserRecoveryActionNotifierProvider, (error) {
        switch (error) {
          case TwoFARequiredException(:final twoFAOptionsCount):
            twoFAOptionsCountRef.value = twoFAOptionsCount;
            step.value = RecoverUserStep.twoFAOptions;
          case InvalidTwoFaCodeException():
            showSimpleBottomSheet<void>(
              context: ref.context,
              child: const TwoFaTryAgainPage(),
            );
          case InvalidRecoveryCredentialsException():
            showSimpleBottomSheet<void>(
              context: ref.context,
              child: const RecoverInvalidCredentialsErrorAlert(),
            );
          default:
        }
      })
      ..displayErrors(
        initUserRecoveryActionNotifierProvider,
        excludedExceptions: {
          TwoFARequiredException,
          InvalidTwoFaCodeException,
          InvalidRecoveryCredentialsException,
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
              ref.read(completeUserRecoveryActionNotifierProvider.notifier).completeRecovery(
                    username: recoveryCreds.value!.name,
                    credentialId: recoveryCreds.value!.id,
                    recoveryKey: recoveryCreds.value!.code,
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
    required ObjectRef<RecoveryCreds?> recoveryCreds,
  }) {
    ref.listenSuccess(
      completeUserRecoveryActionNotifierProvider,
      (value) {
        value?.whenOrNull(
          success: () async {
            final creds = recoveryCreds.value;
            if (creds == null) return;
            final wasPasskeyCompletion = step.value != RecoverUserStep.setNewPassword;
            if (wasPasskeyCompletion) {
              final ionIdentity = await ref.read(ionIdentityProvider.future);
              await ionIdentity(username: creds.name).auth.clearPasswordUserState();
            }
            if (ref.context.mounted) {
              await RecoverUserSuccessRoute().push<void>(ref.context);
            }
          },
        );
      },
    );
  }
}
