// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class RecoveryKeyInput extends HookWidget {
  const RecoveryKeyInput({
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.scrollPadding,
    this.onChanged,
    this.autoValidateMode,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final Widget prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final EdgeInsetsDirectional? scrollPadding;
  final VoidCallback? onChanged;
  final AutovalidateMode? autoValidateMode;

  @override
  Widget build(BuildContext context) {
    final isValid = useState(false);

    final validate = useCallback(
      (String? value) {
        final error = validator?.call(value);
        isValid.value = (value?.isNotEmpty ?? false) && error == null;
        return error;
      },
      [validator],
    );

    useEffect(
      () {
        validate(controller.text);
        return null;
      },
      [],
    );

    return TextInput(
      restorationId: 'recovery_key_input',
      controller: controller,
      labelText: labelText,
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [prefixIcon],
      ),
      suffixIcon: isValid.value
          ? TextInputIcons(
              icons: [Assets.svg.iconBlockCheckboxOn.icon()],
            )
          : null,
      validator: validate,
      textInputAction: textInputAction,
      scrollPadding: scrollPadding ?? EdgeInsetsDirectional.only(bottom: 200.0.s),
      verified: isValid.value,
      onChanged: (text) {
        validate(text);
        onChanged?.call();
      },
      autoValidateMode: autoValidateMode,
    );
  }
}
