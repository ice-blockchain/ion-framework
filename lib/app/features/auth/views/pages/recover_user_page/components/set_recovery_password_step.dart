// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_border.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_password/password_validation.dart';
import 'package:ion/app/features/components/verify_identity/components/password_input.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SetRecoveryPasswordStep extends HookConsumerWidget {
  const SetRecoveryPasswordStep({
    required this.identityKeyName,
    required this.onContinue,
    required this.onBackPress,
    this.isLoading = false,
    super.key,
  });

  final String identityKeyName;
  final void Function(String newPassword) onContinue;
  final VoidCallback onBackPress;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useRef(GlobalKey<FormState>());
    final passwordController = useTextEditingController();
    final passwordConfirmationController = useTextEditingController();
    final passwordInputFocused = useState<bool>(false);
    final passwordConfirmationInputFocused = useState<bool>(false);
    final passwordsError = useState<String?>(null);
    final focusedPasswordValue = useState<String?>(null);

    final identityController = useTextEditingController(text: identityKeyName);

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
          title: context.i18n.recovery_set_new_password_title,
          description: context.i18n.recovery_set_new_password_description,
          icon: Assets.svg.iconLoginPassword.icon(size: 36.0.s),
          onBackPress: onBackPress,
          children: [
            ScreenSideOffset.large(
              child: Form(
                key: formKey.value,
                child: Column(
                  children: [
                    SizedBox(height: 24.0.s),
                    TextInput(
                      enabled: false,
                      controller: identityController,
                      labelText: context.i18n.common_identity_key_name,
                      color: context.theme.appColors.primaryText.withValues(alpha: 0.5),
                      disabledBorder: TextInputBorder(
                        borderSide: BorderSide(
                          color: context.theme.appColors.strokeElements.withValues(alpha: 0.5),
                        ),
                      ),
                      fillColor: context.theme.appColors.secondaryBackground,
                      floatingLabelColor:
                          context.theme.appColors.tertiaryText.withValues(alpha: 0.5),
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
                    Button(
                      disabled: isLoading,
                      trailingIcon: isLoading ? const IONLoadingIndicator() : null,
                      onPressed: () {
                        if (passwordController.text == passwordConfirmationController.text) {
                          passwordsError.value = null;
                          if (formKey.value.currentState!.validate()) {
                            onContinue(passwordController.text);
                          }
                        } else {
                          passwordsError.value = context.i18n.error_passwords_are_not_equal;
                        }
                      },
                      label: Text(context.i18n.recovery_set_new_password_button),
                      mainAxisSize: MainAxisSize.max,
                    ),
                    SizedBox(height: 16.0.s),
                  ],
                ),
              ),
            ),
            ScreenBottomOffset(
              child: const AuthFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
