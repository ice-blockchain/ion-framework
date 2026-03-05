// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';

class TwoFaEditNewValueInputStep extends HookWidget {
  const TwoFaEditNewValueInputStep({
    required this.onNext,
    required this.inputFieldIcon,
    required this.inputFieldLabel,
    required this.inputKeyboardType,
    required this.validator,
    this.restorationId,
    super.key,
  });

  final void Function(String value) onNext;
  final Widget inputFieldIcon;
  final String inputFieldLabel;
  final TextInputType inputKeyboardType;
  final String? Function(String?)? validator;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final locale = context.i18n;
    final formKey = useRef(GlobalKey<FormState>());
    final valueController = useTextEditingController.fromValue(TextEditingValue.empty);

    return Form(
      key: formKey.value,
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return ScreenSideOffset.large(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isKeyboardVisible) SizedBox(height: 58.0.s),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 20.0.s),
                  child: TextInput(
                    restorationId: restorationId,
                    prefixIcon: TextInputIcons(
                      hasRightDivider: true,
                      icons: [inputFieldIcon],
                    ),
                    labelText: inputFieldLabel,
                    controller: valueController,
                    keyboardType: inputKeyboardType,
                    validator: validator,
                    textInputAction: TextInputAction.done,
                    scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
                  ),
                ),
                const Spacer(),
                ScreenBottomOffset(
                  margin: 48.0.s,
                  child: Button(
                    mainAxisSize: MainAxisSize.max,
                    label: Text(locale.button_next),
                    onPressed: () async {
                      final isFormValid = formKey.value.currentState?.validate() ?? false;
                      if (!isFormValid) {
                        return;
                      }
                      onNext(valueController.text);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
