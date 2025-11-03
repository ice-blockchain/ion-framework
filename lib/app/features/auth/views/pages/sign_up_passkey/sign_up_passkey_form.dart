// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/flows/run_sign_up_then_login.dart';
import 'package:ion/app/features/auth/providers/auth_flow_action_notifier.r.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/views/components/identity_key_name_input/identity_key_name_input.dart';
import 'package:ion/app/features/components/biometrics/hooks/use_on_suggest_biometrics.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class SignUpPasskeyForm extends HookConsumerWidget {
  const SignUpPasskeyForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityKeyNameController = useTextEditingController();
    final formKey = useRef(GlobalKey<FormState>());

    final onSuggestToAddBiometrics = useOnSuggestToAddBiometrics(ref);

    final authState = ref.watch(authProvider);
    final authFlowState = ref.watch(authFlowActionNotifierProvider);

    useOnInit(
      () {
        if (authFlowState.hasError && authFlowState.error is PlatformException) {
          context.pop(false);
        }
      },
      [authFlowState.hasError, authFlowState.error],
    );

    ref.displayErrors(
      authFlowActionNotifierProvider,
      excludedExceptions: {...excludedPasskeyExceptions, UserAlreadyExistsException},
    );

    return Form(
      key: formKey.value,
      child: Column(
        children: [
          IdentityKeyNameInput(
            errorText: switch (authFlowState.error) {
              final PasskeyCancelledException _ => null,
              final UserAlreadyExistsException _ => null,
              final IONIdentityException identityException => identityException.title(context),
              _ => authFlowState.error?.toString()
            },
            controller: identityKeyNameController,
          ),
          SizedBox(height: 16.0.s),
          Button(
            disabled: authFlowState.isLoading,
            trailingIcon:
                authFlowState.isLoading || (authState.valueOrNull?.isAuthenticated).falseOrValue
                    ? const IONLoadingIndicator()
                    : Assets.svg.iconButtonNext.icon(
                        size: 24.0.s,
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
            onPressed: () async {
              if (formKey.value.currentState!.validate()) {
                FocusScope.of(context).unfocus();
                await runSignUpThenLogin(
                  context: ref.context,
                  ref: ref,
                  identityKeyName: identityKeyNameController.text,
                  kind: SignUpKind.passkey,
                  suggestBiometrics: onSuggestToAddBiometrics,
                );
              }
            },
            label: Text(context.i18n.button_continue),
            mainAxisSize: MainAxisSize.max,
          ),
        ],
      ),
    );
  }
}
