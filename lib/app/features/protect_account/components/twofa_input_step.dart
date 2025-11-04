// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/warning_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/data/models/twofa_type.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_code_input.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/request_twofa_code_notifier.r.dart';

class TwoFAInputStep extends HookConsumerWidget {
  const TwoFAInputStep({
    required this.twoFaTypes,
    required this.onConfirm,
    super.key,
  });

  final List<TwoFaType> twoFaTypes;
  final void Function(Map<TwoFaType, String> values) onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRequesting = ref.watch(
      requestTwoFaCodeNotifierProvider.select(
        (value) => value.isLoading,
      ),
    );

    final formKey = useRef(GlobalKey<FormState>());

    final controllers = {
      for (final type in twoFaTypes)
        type: useTextEditingController.fromValue(TextEditingValue.empty),
    };

    return ScreenSideOffset.large(
      child: Form(
        key: formKey.value,
        child: CustomScrollView(
          slivers: [
            SliverList.builder(
              itemCount: twoFaTypes.length,
              itemBuilder: (context, index) {
                final twoFaType = twoFaTypes[index];
                return Padding(
                  key: ValueKey(twoFaType),
                  padding: EdgeInsetsDirectional.only(bottom: 22.0.s),
                  child: TwoFaCodeInput(
                    controller: controllers[twoFaType]!,
                    twoFaType: twoFaType,
                    onRequestCode: () async {
                      await ref
                          .read(requestTwoFaCodeNotifierProvider.notifier)
                          .requestTwoFaCode(twoFaType);
                    },
                    isSending: isRequesting,
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
                    ScreenBottomOffset(
                      margin: 48.0.s,
                      child: Button(
                        mainAxisSize: MainAxisSize.max,
                        label: Text(context.i18n.button_confirm),
                        onPressed: () {
                          if (formKey.value.currentState!.validate()) {
                            onConfirm(
                              {
                                for (final controller in controllers.entries)
                                  controller.key: controller.value.text,
                              },
                            );
                          }
                        },
                      ),
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
