// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class IdentityKeyNameSelectorInput extends HookWidget {
  const IdentityKeyNameSelectorInput({
    required this.textController,
    required this.isOpened,
    required this.menuController,
    required this.menuEnabled,
    this.onFocused,
    this.initialValue,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final TextEditingController textController;
  final ValueNotifier<bool> isOpened;
  final MenuController menuController;
  final ValueChanged<bool>? onFocused;
  final bool menuEnabled;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextInput(
      restorationId: 'identity_key_name_selector_input',
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [Assets.svg.iconRestorekey.icon()],
      ),
      suffixIcon: menuEnabled
          ? TextInputIcons(
              icons: [
                SizedBox.square(
                  dimension: 40.0.s,
                  child: IconButton(
                    icon:
                        (isOpened.value ? Assets.svg.iconArrowUp : Assets.svg.iconArrowDown).icon(),
                    onPressed: () {
                      isOpened.value = !isOpened.value;
                      if (menuController.isOpen) {
                        menuController.close();
                      } else {
                        menuController.open();
                      }
                    },
                  ),
                ),
              ],
            )
          : null,
      labelText: context.i18n.restore_from_cloud_selector_title,
      controller: textController,
      textInputAction: TextInputAction.done,
      scrollPadding: EdgeInsetsDirectional.only(bottom: 200.0.s),
      onFocused: onFocused,
      errorText: errorText,
      onChanged: onChanged,
    );
  }
}
