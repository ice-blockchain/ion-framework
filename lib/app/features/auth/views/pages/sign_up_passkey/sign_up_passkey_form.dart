// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/register_action_notifier.r.dart';
import 'package:ion/app/features/auth/views/components/identity_key_name_input/identity_key_name_input.dart';
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

    final authState = ref.watch(authProvider);
    final registerActionState = ref.watch(registerActionNotifierProvider);

    useOnInit(
      () {
        if (registerActionState.hasError && registerActionState.error is PlatformException) {
          context.pop(false);
        }
      },
      [registerActionState.hasError, registerActionState.error],
    );

    ref.displayErrors(
      registerActionNotifierProvider,
      excludedExceptions: excludedPasskeyExceptions,
    );

    return Form(
      key: formKey.value,
      child: Column(
        children: [
          IdentityKeyNameInput(
            errorText: switch (registerActionState.error) {
              final PasskeyCancelledException _ => null,
              final IONIdentityException identityException => identityException.title(context),
              _ => registerActionState.error?.toString()
            },
            controller: identityKeyNameController,
          ),
          SizedBox(height: 16.0.s),
          Button(
            disabled: registerActionState.isLoading,
            trailingIcon: registerActionState.isLoading ||
                    (authState.valueOrNull?.isAuthenticated).falseOrValue
                ? const IONLoadingIndicator()
                : Assets.svg.iconButtonNext.icon(
                    size: 24.0.s,
                    color: context.theme.appColors.onPrimaryAccent,
                  ),
            onPressed: () {
              if (formKey.value.currentState!.validate()) {
                FocusScope.of(context).unfocus();
                guardPasskeyDialog(
                  ref.context,
                  (child) => RiverpodUserActionSignerRequestBuilder(
                    provider: registerActionNotifierProvider,
                    identityKeyName: identityKeyNameController.text,
                    request: (_) async {
                      await ref
                          .read(registerActionNotifierProvider.notifier)
                          .signUp(keyName: identityKeyNameController.text);
                    },
                    child: child,
                  ),
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
