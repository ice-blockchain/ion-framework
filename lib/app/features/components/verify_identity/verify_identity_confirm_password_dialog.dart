// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/components/password_input.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class VerifyIdentityConfirmPasswordDialog<T> extends HookConsumerWidget {
  const VerifyIdentityConfirmPasswordDialog({
    required this.onPasswordFlow,
    super.key,
  });

  final OnPasswordFlow<T> onPasswordFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;
    final i18n = context.i18n;

    final passwordController = useTextEditingController();
    final formKey = useRef(GlobalKey<FormState>());

    final validationErrorMessage = useState<String?>(null);
    final processing = useState<bool>(false);

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.0.s),
        child: Form(
          key: formKey.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30.0.s),
              Assets.svg.actionWalletVerifywithpass.icon(size: 80.0.s),
              SizedBox(height: 6.0.s),
              Text(
                i18n.verify_with_password_title,
                textAlign: TextAlign.center,
                style: textThemes.title,
              ),
              SizedBox(height: 8.0.s),
              Text(
                i18n.verify_with_password_desc,
                textAlign: TextAlign.center,
                style: textThemes.body2.copyWith(color: colors.secondaryText),
              ),
              SizedBox(height: 20.0.s),
              PasswordInput(
                controller: passwordController,
                passwordInputMode: PasswordInputMode.verify,
                errorText: validationErrorMessage.value,
              ),
              SizedBox(height: 25.0.s),
              Button(
                disabled: processing.value,
                trailingIcon: processing.value ? const IONLoadingIndicator() : null,
                onPressed: () async {
                  if (formKey.value.currentState!.validate()) {
                    processing.value = true;
                    validationErrorMessage.value = null;
                    try {
                      Navigator.of(context)
                          .pop(await onPasswordFlow(password: passwordController.text));
                    } on InvalidPasswordException {
                      if (context.mounted) {
                        validationErrorMessage.value = context.i18n.error_invalid_password;
                      }
                    } finally {
                      processing.value = false;
                    }
                  }
                },
                label: Text(context.i18n.button_confirm),
                mainAxisSize: MainAxisSize.max,
              ),
              ScreenBottomOffset(margin: 16.0.s),
            ],
          ),
        ),
      ),
    );
  }
}
