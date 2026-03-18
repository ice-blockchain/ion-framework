// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/hooks/use_text_changed.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class IdentityKeyNameSelectorInput extends HookWidget {
  const IdentityKeyNameSelectorInput({
    required this.textController,
    required this.isOpened,
    required this.menuEnabled,
    required this.onToggleMenu,
    this.onFocused,
    this.initialValue,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final TextEditingController textController;
  final ValueNotifier<bool> isOpened;
  final ValueChanged<bool>? onFocused;
  final bool menuEnabled;
  final VoidCallback onToggleMenu;
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final showClear = useState(textController.text.isNotEmpty);

    useTextChanged(
      controller: textController,
      onTextChanged: (text) => showClear.value = text.isNotEmpty,
    );

    return TextInput(
      prefixIcon: TextInputIcons(
        hasRightDivider: true,
        icons: [Assets.svg.iconRestorekey.icon()],
      ),
      suffixIcon: menuEnabled
          ? TextInputIcons(
              minWidth: 0,
              icons: [
                if (!isOpened.value && showClear.value)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: textController.clear,
                    icon: Assets.svg.iconFieldClearall.icon(),
                  ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: (isOpened.value ? Assets.svg.iconArrowUp : Assets.svg.iconArrowDown).icon(),
                  onPressed: onToggleMenu,
                ),
                SizedBox(
                  width: 16.0.s,
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
