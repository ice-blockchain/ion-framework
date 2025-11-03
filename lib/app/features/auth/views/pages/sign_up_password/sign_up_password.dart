// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/flows/run_sign_up_then_login.dart';
import 'package:ion/app/features/auth/providers/auth_flow_action_notifier.r.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/components/identity_key_name_input/identity_key_name_input.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_password/password_validation.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_password/sign_up_password_button.dart';
import 'package:ion/app/features/components/biometrics/hooks/use_on_suggest_biometrics.dart';
import 'package:ion/app/features/components/verify_identity/components/password_input.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class SignUpPasswordPage extends HookConsumerWidget {
  const SignUpPasswordPage({super.key});

  static double get _footerHeight => 92.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityKeyNameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final passwordConfirmationController = useTextEditingController();
    final passwordInputFocused = useState<bool>(false);
    final passwordConfirmationInputFocused = useState<bool>(false);

    final formKey = useRef(GlobalKey<FormState>());

    ref.displayErrors(
      authFlowActionNotifierProvider,
      excludedExceptions: {UserAlreadyExistsException},
    );
    final onSuggestToAddBiometrics = useOnSuggestToAddBiometrics(ref);

    final passwordsError = useState<String?>(null);
    final focusedPasswordValue = useState<String?>(null);
    final onFocusedPasswordValue = useCallback(
      (String value) {
        passwordsError.value = null;
        focusedPasswordValue.value = value;
      },
      [],
    );

    useEffect(
      () {
        if (passwordInputFocused.value) {
          focusedPasswordValue.value = passwordController.text;
        }
        if (passwordConfirmationInputFocused.value) {
          focusedPasswordValue.value = passwordConfirmationController.text;
        }
        return null;
      },
      [
        passwordInputFocused.value,
        passwordConfirmationInputFocused.value,
      ],
    );

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.sign_up_password_title,
          description: context.i18n.sign_up_password_description,
          icon: Assets.svg.iconLoginPassword.icon(size: 36.0.s),
          children: [
            ScreenSideOffset.large(
              child: Form(
                key: formKey.value,
                child: Column(
                  children: [
                    SizedBox(height: 60.0.s),
                    IdentityKeyNameInput(
                      controller: identityKeyNameController,
                      textInputAction: TextInputAction.next,
                      scrollPadding: EdgeInsetsDirectional.only(bottom: 250.0.s),
                    ),
                    SizedBox(height: 16.0.s),
                    PasswordInput(
                      controller: passwordController,
                      passwordInputMode: PasswordInputMode.create,
                      errorText: passwordsError.value,
                      onFocused: (value) => passwordInputFocused.value = value,
                      onValueChanged: onFocusedPasswordValue,
                    ),
                    SizedBox(height: 16.0.s),
                    PasswordInput(
                      isConfirmation: true,
                      controller: passwordConfirmationController,
                      passwordInputMode: PasswordInputMode.create,
                      errorText: passwordsError.value,
                      onFocused: (value) => passwordConfirmationInputFocused.value = value,
                      onValueChanged: onFocusedPasswordValue,
                    ),
                    SizedBox(height: 16.0.s),
                    PasswordValidation(
                      password: focusedPasswordValue.value,
                      showValidation:
                          passwordInputFocused.value || passwordConfirmationInputFocused.value,
                    ),
                    SizedBox(height: 22.0.s),
                    SignUpPasswordButton(
                      onPressed: () async {
                        if (passwordController.text == passwordConfirmationController.text) {
                          if (formKey.value.currentState!.validate()) {
                            await runSignUpThenLogin(
                              context: ref.context,
                              ref: ref,
                              identityKeyName: identityKeyNameController.text,
                              kind: SignUpKind.password,
                              password: passwordController.text,
                              suggestBiometrics: onSuggestToAddBiometrics,
                            );
                          }
                        } else {
                          passwordsError.value = context.i18n.error_passwords_are_not_equal;
                        }
                      },
                    ),
                    SizedBox(
                      height: 56.0.s,
                    ),
                    const AuthFooter(),
                  ],
                ),
              ),
            ),
            ScreenBottomOffset(margin: _footerHeight),
          ],
        ),
      ),
    );
  }
}
