// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar/actions_toolbar.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_buttons.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';

class ArticleTypographyToolbar extends StatelessWidget {
  const ArticleTypographyToolbar({
    required this.textEditorController,
    required this.onClosePressed,
    super.key,
  });

  final QuillController textEditorController;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return ActionsToolbar(
      actions: [
        ToolbarCloseButton(
          textEditorController: textEditorController,
          onPressed: () {
            hideKeyboard(context);
            onClosePressed();
          },
        ),
        ToolbarH1Button(textEditorController: textEditorController),
        ToolbarH2Button(textEditorController: textEditorController),
        ToolbarH3Button(textEditorController: textEditorController),
        ToolbarBoldButton(textEditorController: textEditorController),
        ToolbarItalicButton(textEditorController: textEditorController),
        ToolbarUnderlineButton(textEditorController: textEditorController),
        ToolbarLinkButton(textEditorController: textEditorController),
      ],
    );
  }
}
