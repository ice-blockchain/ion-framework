// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/warning_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_option_selector.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';

class TwoFASelectOptionStep extends ConsumerWidget {
  const TwoFASelectOptionStep({
    required this.formKey,
    required this.twoFaType,
    required this.onConfirm,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TwoFaType twoFaType;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsState = ref.watch(selectedTwoFAOptionsNotifierProvider);

    return ScreenSideOffset.large(
      child: Form(
        key: formKey,
        child: CustomScrollView(
          slivers: [
            SliverList.builder(
              itemCount: optionsState.optionsAmount,
              itemBuilder: (context, option) {
                return Padding(
                  key: ValueKey(option),
                  padding: EdgeInsetsDirectional.only(bottom: 22.0.s),
                  child: TwoFaOptionSelector(
                    availableOptions: optionsState.availableOptions,
                    selectedOptions: optionsState.selectedValues,
                    initialValue: optionsState.selectedValues[option],
                    optionIndex: option + 1,
                    onSaved: (value) {
                      ref
                          .read(selectedTwoFAOptionsNotifierProvider.notifier)
                          .updateSelectedTwoFaOption(option, value);
                    },
                  ),
                );
              },
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WarningCard(
                      text: context.i18n.two_fa_warning,
                    ),
                    SizedBox(
                      height: 24.0.s,
                    ),
                    Button(
                      mainAxisSize: MainAxisSize.max,
                      label: Text(context.i18n.button_confirm),
                      onPressed: () {
                        formKey.currentState!.save();
                        if (formKey.currentState!.validate()) {
                          onConfirm();
                        }
                      },
                    ),
                    SizedBox(
                      height: 48.0.s,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
