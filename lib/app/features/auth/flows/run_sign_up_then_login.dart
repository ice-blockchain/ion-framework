// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_flow_action_notifier.r.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';

typedef SuggestBiometrics = Future<void> Function({
  required String username,
  required String password,
});

Future<void> runSignUpThenLogin({
  required BuildContext context,
  required WidgetRef ref,
  required String identityKeyName,
  required SignUpKind kind,
  String? password,
  SuggestBiometrics? suggestBiometrics,
}) async {
  String? capturedPassword;

  await guardPasskeyDialog(
    context,
    (child) => RiverpodAuthConfigRequestBuilder(
      provider: authFlowActionNotifierProvider,
      identityKeyName: identityKeyName,
      onPasswordCaptured: (pwd) => capturedPassword = pwd,
      request: (config) async {
        await ref.read(authFlowActionNotifierProvider.notifier).signUpOrLogin(
              keyName: identityKeyName,
              config: config,
              kind: kind,
              password: password,
            );
      },
      child: child,
    ),
    identityKeyName: identityKeyName,
  );

  if (suggestBiometrics != null) {
    final flowState = ref.read(authFlowActionNotifierProvider);
    if (!flowState.hasError) {
      final ionIdentity = await ref.read(ionIdentityProvider.future);
      final isPasswordUser = ionIdentity(username: identityKeyName).auth.isPasswordFlowUser();
      final biometricsState = ionIdentity(username: identityKeyName).auth.getBiometricsState();
      if (isPasswordUser && biometricsState == BiometricsState.canSuggest) {
        final pwd = password ?? capturedPassword;
        if (pwd != null) {
          await suggestBiometrics(username: identityKeyName, password: pwd);
        }
      }
    }
  }
}
