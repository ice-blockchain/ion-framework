// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class MemoInputField extends HookWidget {
  const MemoInputField({
    required this.onMemoChanged,
    this.memo,
    super.key,
  });

  final ValueChanged<String> onMemoChanged;
  final String? memo;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    useOnInit(() => controller.text = memo ?? '', [memo]);

    return TextInput(
      controller: controller,
      labelText: context.i18n.wallet_memo,
      onChanged: onMemoChanged,
    );
  }
}
