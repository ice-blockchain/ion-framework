// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_screen_busy_provider.r.dart';
import 'package:ion/app/features/auth/providers/login_action_notifier.r.dart';
import 'package:ion/app/features/auth/views/components/identity_key_name_input/identity_key_name_input.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class LoginForm extends HookConsumerWidget {
  const LoginForm({
    required this.onLogin,
    super.key,
  });

  final void Function(String username) onLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityKeyNameController = useTextEditingController();
    final formKey = useRef(GlobalKey<FormState>());

    final loginActionState = ref.watch(loginActionNotifierProvider);
    useEffect(
      () {
        void listener() {
          if (identityKeyNameController.text.isNotEmpty) {
            ref.read(loginActionNotifierProvider.notifier).cancelAutoPasskeyLogin();
          }
        }

        identityKeyNameController.addListener(listener);
        return () => identityKeyNameController.removeListener(listener);
      },
      [identityKeyNameController],
    );

    final authScreenIsBusy = ref.watch(authScreenBusyProvider);

    return Form(
      key: formKey.value,
      child: Column(
        children: [
          IdentityKeyNameInput(
            errorText: switch (loginActionState.error) {
              final PasskeyCancelledException _ => null,
              final IONIdentityException identityException => identityException.title(context),
              _ => loginActionState.error?.toString(),
            },
            controller: identityKeyNameController,
            scrollPadding: EdgeInsetsDirectional.only(bottom: 88.0.s),
            onFocused: (focused) {
              if (authScreenIsBusy) return;
              final isIdentityKeyNameEmpty = identityKeyNameController.text.isEmpty;
              if (!focused || !isIdentityKeyNameEmpty) {
                return;
              }
              onLogin('');
            },
          ),
          SizedBox(height: 16.0.s),
          Button(
            disabled: authScreenIsBusy,
            trailingIcon: authScreenIsBusy
                ? const IONLoadingIndicator()
                : Assets.svg.iconButtonNext.icon(color: context.theme.appColors.onPrimaryAccent),
            onPressed: authScreenIsBusy
                ? null
                : () {
                    if (formKey.value.currentState!.validate()) {
                      onLogin(identityKeyNameController.text);
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
