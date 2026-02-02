// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
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

    final authState = ref.watch(authProvider);
    final loginActionState = ref.watch(loginActionNotifierProvider);

    final autoPasskeyLoginTriggered = useState(false);
    useEffect(
      () {
        return () => ref.read(loginActionNotifierProvider.notifier).cancelAutoPasskeyLogin();
      },
      const [],
    );

    useEffect(
      () {
        if (!loginActionState.isLoading) {
          autoPasskeyLoginTriggered.value = false;
        }
        return null;
      },
      [loginActionState.isLoading],
    );

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
              if (!focused) {
                return;
              }

              final isIdentityKeyNameEmpty = identityKeyNameController.text.isEmpty;

              // If an auto-passkey login is running and the user taps the field again
              // (usually to type manually), cancel the native authenticator operation
              // and allow manual input.
              if (autoPasskeyLoginTriggered.value && loginActionState.isLoading) {
                autoPasskeyLoginTriggered.value = false;
                ref.read(loginActionNotifierProvider.notifier).cancelAutoPasskeyLogin();
                return;
              }

              // Only attempt auto-passkey login when the field is empty and no other login is running.
              if (!isIdentityKeyNameEmpty || loginActionState.isLoading) {
                return;
              }

              autoPasskeyLoginTriggered.value = true;

              // Best-effort: remove focus and hide the keyboard before we trigger the
              // Credential Manager / passkey flow (helps with some Android/Samsung hangs).
              FocusManager.instance.primaryFocus?.unfocus();
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              try {
                TextInput.finishAutofillContext(shouldSave: false);
              } catch (_) {
                // ignore: best-effort
              }

              Future.microtask(() {
                if (!context.mounted) return;
                onLogin('');
              });
            },
          ),
          SizedBox(height: 16.0.s),
          Button(
            disabled: loginActionState.isLoading,
            trailingIcon: loginActionState.isLoading ||
                    (authState.valueOrNull?.isAuthenticated).falseOrValue
                ? const IONLoadingIndicator()
                : Assets.svg.iconButtonNext.icon(color: context.theme.appColors.onPrimaryAccent),
            onPressed: () {
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
