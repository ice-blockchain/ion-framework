// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/modal_sheets/simple_modal_sheet.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/components/twofa_step_scaffold.dart';
import 'package:ion/app/features/protect_account/email/providers/linked_phone_provider.r.dart';
import 'package:ion/app/features/protect_account/phone/views/components/phone/phone_input_step.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class PhoneEditNewPhoneInputStep extends HookConsumerWidget {
  const PhoneEditNewPhoneInputStep({required this.onNext, super.key});

  final void Function(String phone) onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final linkedPhone = ref.watch(linkedPhoneProvider).valueOrNull;

    return TwoFAStepScaffold(
      headerIcon: Assets.svg.icon2faPhoneconfirm.icon(size: 36.0.s),
      headerTitle: locale.two_fa_edit_phone_title,
      headerDescription: locale.two_fa_edit_phone_new_phone_description,
      contentPadding: 0,
      child: PhoneInputStep(
        restorationId: 'phone_edit_input',
        onNext: (String phone) {
          if (linkedPhone != null && linkedPhone == phone) {
            _showPhoneAlreadyLinkedModal(ref);
          } else {
            onNext(phone);
          }
        },
      ),
    );
  }

  void _showPhoneAlreadyLinkedModal(WidgetRef ref) {
    showSimpleBottomSheet<void>(
      context: ref.context,
      child: SimpleModalSheet.alert(
        iconAsset: Assets.svg.actionWalletKeyserror,
        title: ref.context.i18n.common_error,
        description: ref.context.i18n.two_fa_edit_phone_already_linked,
        buttonText: ref.context.i18n.button_try_again,
        isBottomSheet: true,
        bottomOffset: 0.0.s,
        topOffset: 30.0.s,
      ),
    );
  }
}
