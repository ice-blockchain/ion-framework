// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/protect_account/components/two_fa_edit_new_value_input_step.dart';
import 'package:ion/app/features/protect_account/components/twofa_step_scaffold.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

class EmailEditNewEmailInputStep extends HookConsumerWidget {
  const EmailEditNewEmailInputStep({required this.onNext, super.key});

  final void Function(String email) onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;

    return TwoFAStepScaffold(
      headerIcon: Assets.svg.icon2faEmailauth.icon(size: 36.0.s),
      headerTitle: locale.two_fa_edit_email_title,
      headerDescription: locale.two_fa_edit_email_new_email_description,
      contentPadding: 0,
      child: TwoFaEditNewValueInputStep(
        restorationId: 'email_edit_new_email_input',
        onNext: onNext,
        inputFieldIcon: TwoFaType.email.iconAsset.icon(),
        inputFieldLabel: context.i18n.common_email_address,
        inputKeyboardType: TextInputType.emailAddress,
        validator: (value) => Validators.isInvalidEmail(value) ? '' : null,
      ),
    );
  }
}
