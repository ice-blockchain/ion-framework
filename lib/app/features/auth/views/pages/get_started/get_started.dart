// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/login_action_notifier.r.dart';
import 'package:ion/app/features/auth/views/pages/get_started/components/sign_in_step.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_input_step.dart';
import 'package:ion/app/features/auth/views/pages/two_fa/twofa_options_step.dart';
import 'package:ion/app/features/components/biometrics/hooks/use_on_suggest_biometrics.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';
import 'package:ion_identity_client/ion_identity.dart';

enum GetStartedPageStep {
  signIn,
  twoFAOptions,
  twoFAInput,
}

class GetStartedPage extends HookConsumerWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(GetStartedPageStep.signIn);
    final twoFAOptions = useRef<Map<TwoFaType, String>?>(null);
    final twoFAOptionsCount = useRef<int>(0);
    final usernameRef = useRef<String>('');

    final authState = ref.watch(authProvider);
    final loginActionState = ref.watch(loginActionNotifierProvider);

    ref.displayErrors(
      loginActionNotifierProvider,
      excludedExceptions: {
        TwoFARequiredException,
        NoLocalPasskeyCredsFoundIONIdentityException,
        ...excludedPasskeyExceptions,
      },
    );

    final onSuggestToAddBiometrics = useOnSuggestToAddBiometrics(ref);

    return switch (step.value) {
      GetStartedPageStep.signIn => SignInStep(
          step: step,
          twoFAOptions: twoFAOptions,
          twoFAOptionsCount: twoFAOptionsCount,
          usernameRef: usernameRef,
          showSignInDialog: _showSignInDialog,
        ),
      GetStartedPageStep.twoFAOptions => ProviderScope(
          overrides: [
            availableTwoFaTypesProvider.overrideWithValue(
              (types: TwoFaType.values, count: twoFAOptionsCount.value),
            ),
          ],
          child: TwoFAOptionsStep(
            twoFAOptionsCount: twoFAOptionsCount.value,
            onConfirm: () => step.value = GetStartedPageStep.twoFAInput,
            onBackPress: () => step.value = GetStartedPageStep.signIn,
          ),
        ),
      GetStartedPageStep.twoFAInput => ProviderScope(
          overrides: [
            availableTwoFaTypesProvider.overrideWithValue(
              (types: TwoFaType.values, count: twoFAOptionsCount.value),
            ),
          ],
          child: TwoFAInputStep(
            identityKeyName: usernameRef.value,
            isLoading:
                loginActionState.isLoading || (authState.valueOrNull?.isAuthenticated).falseOrValue,
            onBackPress: () => step.value = GetStartedPageStep.twoFAOptions,
            onContinuePressed: (twoFaTypes) async {
              twoFAOptions.value = twoFaTypes;
              final loginPassword = await _showSignInDialog(
                ref,
                identityKeyName: usernameRef.value,
                localCredsOnly: false,
                twoFaTypes: twoFAOptions.value,
              );
              if (loginPassword != null) {
                await onSuggestToAddBiometrics(
                  username: usernameRef.value,
                  password: loginPassword,
                );
              }
            },
          ),
        ),
    };
  }

  Future<String?> _showSignInDialog(
    WidgetRef ref, {
    required String identityKeyName,
    required bool localCredsOnly,
    required Map<TwoFaType, String>? twoFaTypes,
  }) async {
    String? loginPassword;
    await guardPasskeyDialog(
      ref.context,
      identityKeyName: identityKeyName,
      (child) => RiverpodAuthConfigRequestBuilder<void>(
        identityKeyName: identityKeyName,
        onPasswordCaptured: (String p) => loginPassword = p,
        request: (AuthConfig config) async {
          await ref.read(loginActionNotifierProvider.notifier).verifyUserLoginFlow(
                keyName: identityKeyName,
              );
          await ref.read(loginActionNotifierProvider.notifier).signIn(
                keyName: identityKeyName,
                config: config,
                twoFaTypes: twoFaTypes,
                localCredsOnly: localCredsOnly,
              );
        },
        child: child,
      ),
    );
    return loginPassword;
  }
}
