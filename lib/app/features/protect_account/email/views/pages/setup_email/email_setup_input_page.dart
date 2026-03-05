// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/protect_account/email/data/model/email_steps.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/request_twofa_code_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/validators.dart';

class EmailSetupInputPage extends HookConsumerWidget {
  const EmailSetupInputPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final formKey = useRef(GlobalKey<FormState>());
    final emailController = useTextEditingController.fromValue(TextEditingValue.empty);
    final isRequestingCode =
        ref.watch(requestTwoFaCodeNotifierProvider.select((state) => state.isLoading));

    ref
      ..displayErrors(requestTwoFaCodeNotifierProvider)
      ..listenSuccess(requestTwoFaCodeNotifierProvider, (_) {
        if (!context.mounted) {
          return;
        }

        unawaited(
          EmailSetupRoute(
            step: EmailSetupSteps.confirmation,
            email: emailController.text,
          ).push<void>(context),
        );
      });

    return Form(
      key: formKey.value,
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return ScreenSideOffset.large(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isKeyboardVisible) SizedBox(height: 58.0.s),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 20.0.s),
                  child: TextInput(
                    restorationId: 'email_setup_input',
                    prefixIcon: TextInputIcons(
                      hasRightDivider: true,
                      icons: [TwoFaType.email.iconAsset.icon()],
                    ),
                    labelText: context.i18n.common_email_address,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => Validators.isInvalidEmail(value) ? '' : null,
                    textInputAction: TextInputAction.done,
                    scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
                  ),
                ),
                const Spacer(),
                Button(
                  mainAxisSize: MainAxisSize.max,
                  label: Text(locale.button_next),
                  disabled: isRequestingCode,
                  trailingIcon: isRequestingCode ? const IONLoadingIndicator() : null,
                  onPressed: () async {
                    final isFormValid = formKey.value.currentState?.validate() ?? false;
                    if (!isFormValid) {
                      return;
                    }

                    await ref
                        .read(requestTwoFaCodeNotifierProvider.notifier)
                        .requestTwoFaCode(TwoFaType.email, value: emailController.text);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
