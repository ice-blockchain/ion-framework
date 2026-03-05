// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/password_validation_error_type.dart';
import 'package:ion/generated/assets.gen.dart';

enum PasswordInputMode { create, verify }

class PasswordInput extends HookWidget {
  const PasswordInput({
    required this.controller,
    required this.passwordInputMode,
    this.restorationId,
    this.onFocused,
    this.onValueChanged,
    this.isConfirmation = false,
    this.errorText,
    super.key,
  });

  final PasswordInputMode passwordInputMode;
  final TextEditingController controller;
  final ValueChanged<bool>? onFocused;
  final ValueChanged<String>? onValueChanged;
  final bool isConfirmation;
  final String? errorText;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = useState(false);

    return TextInput(
      restorationId: restorationId,
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [Assets.svg.iconPass.icon()],
      ),
      suffixIcon: TextInputIcons(
        icons: [
          SizedBox.square(
            dimension: 40.0.s,
            child: IconButton(
              icon: isPasswordVisible.value
                  ? Assets.svg.iconBlockEyeOff.icon(color: context.theme.appColors.primaryAccent)
                  : Assets.svg.iconBlockEyeOn.icon(color: context.theme.appColors.primaryAccent),
              onPressed: () {
                isPasswordVisible.value = !isPasswordVisible.value;
              },
            ),
          ),
        ],
      ),
      labelText:
          isConfirmation ? context.i18n.common_confirm_password : context.i18n.common_password,
      controller: controller,
      validator: (String? value) => switch (passwordInputMode) {
        PasswordInputMode.create => PasswordValidationErrorType.values
            .firstWhereOrNull((v) => v.isInvalid(value))
            ?.getDisplayName(context),
        PasswordInputMode.verify =>
          PasswordValidationErrorType.values.any((v) => v.isInvalid(value))
              ? context.i18n.error_invalid_password
              : null,
      },
      obscureText: isPasswordVisible.value == false,
      textInputAction: TextInputAction.done,
      scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
      onFocused: onFocused,
      errorText: errorText,
      onChanged: onValueChanged,
    );
  }
}
