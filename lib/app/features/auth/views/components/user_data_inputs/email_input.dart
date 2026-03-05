// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/general_user_data_input.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

const int _nameMaxLength = 320;

class EmailInput extends StatelessWidget {
  const EmailInput({
    this.onChanged,
    this.initialValue,
    this.errorText,
    this.restorationId,
    super.key,
  });

  final ValueChanged<String>? onChanged;

  final String? initialValue;
  final String? errorText;

  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return GeneralUserDataInput(
      restorationId: restorationId,
      onChanged: onChanged,
      prefixIconAssetName: Assets.svg.iconFieldEmail,
      labelText: context.i18n.common_email_address,
      initialValue: initialValue,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      errorText: errorText,
      validator: (String? value) {
        if (Validators.isInvalidEmail(value)) return '';

        if (Validators.isInvalidLength(value, maxLength: _nameMaxLength)) {
          return context.i18n.error_input_length_max(_nameMaxLength);
        }

        return null;
      },
    );
  }
}
