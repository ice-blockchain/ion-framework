// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/hooks/use_text_editor_font_style.dart';
import 'package:ion/app/components/text_editor/utils/quill_style_manager.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar_button/actions_toolbar_button.dart';
import 'package:ion/generated/assets.gen.dart';

class ToolbarItalicButton extends HookWidget {
  const ToolbarItalicButton({required this.textEditorController, super.key});
  final QuillController textEditorController;

  @override
  Widget build(BuildContext context) {
    final fontStyles = useTextEditorFontStyles(textEditorController);
    final styleManager =
        useMemoized(() => QuillStyleManager(textEditorController), [textEditorController]);

    useEffect(() => styleManager.dispose, [styleManager]);

    return ActionsToolbarButton(
      icon: Assets.svg.iconPostItalictextOff,
      iconSelected: Assets.svg.iconPostItalictextOn,
      onPressed: () {
        styleManager.toggleTextStyle(Attribute.italic);
      },
      selected: fontStyles.contains(FontType.italic),
    );
  }
}
