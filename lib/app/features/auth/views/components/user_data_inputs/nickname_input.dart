// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/general_user_data_input.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

const int _nicknameMaxLength = 20;

String? validateNickname(String? value, BuildContext context) {
  if (Validators.isEmpty(value)) return '';

  if (Validators.isInvalidNickname(value)) {
    return context.i18n.error_nickname_invalid;
  }

  if (Validators.isInvalidLength(value, maxLength: _nicknameMaxLength)) {
    return context.i18n.error_input_length_max(_nicknameMaxLength);
  }
  return null;
}

class NicknameInput extends StatelessWidget {
  const NicknameInput({
    this.restorationId,
    super.key,
    this.textInputAction,
    this.onChanged,
    this.initialValue,
    this.errorText,
    this.isLive = false,
  });

  final TextInputAction? textInputAction;

  final ValueChanged<String>? onChanged;

  final String? initialValue;

  final String? errorText;

  final bool isLive;

  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return GeneralUserDataInput(
      restorationId: restorationId,
      onChanged: onChanged,
      prefixIconAssetName: Assets.svg.iconFieldNickname,
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) => newValue.copyWith(
            text: newValue.text.toLowerCase(),
            selection: newValue.selection,
          ),
        ),
      ],
      labelText: context.i18n.fill_profile_input_nickname,
      textInputAction: textInputAction,
      initialValue: initialValue,
      isLive: isLive,
      showNoErrorsIndicator: isLive,
      errorText: errorText,
      validator: (value) => validateNickname(value, context),
    );
  }
}
