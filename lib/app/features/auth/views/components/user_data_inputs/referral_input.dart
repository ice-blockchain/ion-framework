// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/general_user_data_input.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

const int _referralMaxLength = 20;

class ReferralInput extends StatelessWidget {
  const ReferralInput({
    super.key,
    this.textInputAction,
    this.onChanged,
    this.onFocused,
    this.initialValue,
    this.controller,
    this.errorText,
    this.isLive = false,
  });

  final TextInputAction? textInputAction;

  final ValueChanged<String>? onChanged;

  final String? initialValue;

  final TextEditingController? controller;

  final String? errorText;

  final bool isLive;

  final ValueChanged<bool>? onFocused;

  @override
  Widget build(BuildContext context) {
    return GeneralUserDataInput(
      onChanged: onChanged,
      onFocused: onFocused,
      prefixIconAssetName: Assets.svg.iconFieldInviter,
      labelText: context.i18n.fill_profile_input_referral,
      textInputAction: textInputAction,
      controller: controller,
      initialValue: initialValue,
      isLive: isLive,
      showNoErrorsIndicator: isLive,
      errorText: errorText,
      validator: (String? value) {
        if (Validators.isEmpty(value)) return null;

        if (Validators.isInvalidNickname(value)) {
          return context.i18n.error_nickname_invalid;
        }

        if (Validators.isInvalidLength(value, maxLength: _referralMaxLength)) {
          return context.i18n.error_input_length_max(_referralMaxLength);
        }
        return null;
      },
    );
  }
}
