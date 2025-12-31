// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/auth/views/components/auth_footer/auth_footer.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_twofa_page/components/twofa_option_selector.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/selected_two_fa_types_provider.m.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class TwoFAOptionsStep extends HookConsumerWidget {
  const TwoFAOptionsStep({
    required this.twoFAOptionsCount,
    required this.onConfirm,
    required this.onBackPress,
    this.titleIcon,
    super.key,
  });

  final int twoFAOptionsCount;
  final VoidCallback onConfirm;
  final VoidCallback onBackPress;
  final Widget? titleIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useRef(GlobalKey<FormState>());
    final optionsState = ref.watch(selectedTwoFAOptionsNotifierProvider);

    final isFormValid = optionsState.selectedValues.nonNulls.isNotEmpty;

    return SheetContent(
      topPadding: 0,
      body: AuthScrollContainer(
        title: context.i18n.two_fa_title,
        description: context.i18n.two_fa_desc,
        icon: titleIcon ?? Assets.svg.iconWalletProtectFill.icon(size: 36.0.s),
        onBackPress: onBackPress,
        children: [
          Column(
            children: [
              ScreenSideOffset.large(
                child: Form(
                  key: formKey.value,
                  child: Column(
                    children: [
                      SizedBox(height: 16.0.s),
                      ...List.generate(
                        optionsState.optionsAmount,
                        (option) {
                          return Padding(
                            padding: EdgeInsetsDirectional.only(bottom: 16.0.s),
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
                      SizedBox(height: 16.0.s),
                      Button(
                        disabled: !isFormValid,
                        type: isFormValid ? ButtonType.primary : ButtonType.disabled,
                        onPressed: !isFormValid ? null : onConfirm,
                        label: Text(context.i18n.button_confirm),
                        mainAxisSize: MainAxisSize.max,
                      ),
                      SizedBox(height: 16.0.s),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ScreenBottomOffset(
            margin: 28.0.s,
            child: const AuthFooter(),
          ),
        ],
      ),
    );
  }
}
