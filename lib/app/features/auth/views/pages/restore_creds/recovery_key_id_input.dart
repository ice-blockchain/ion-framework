// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

class RecoveryKeyIdInput extends StatelessWidget {
  const RecoveryKeyIdInput({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextInput(
      restorationId: 'recovery_key_id_input',
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [Assets.svg.iconChannelPrivate.icon()],
      ),
      labelText: context.i18n.restore_identity_creds_recovery_key,
      controller: controller,
      validator: (String? value) {
        if (Validators.isEmpty(value)) return '';
        return null;
      },
      textInputAction: TextInputAction.done,
      scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
    );
  }
}
