// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar/actions_toolbar.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_buttons.dart';

class ArticleMainToolbar extends StatelessWidget {
  const ArticleMainToolbar({
    required this.textEditorController,
    required this.textEditorKey,
    required this.onTypographyPressed,
    super.key,
  });

  final QuillController textEditorController;
  final GlobalKey<TextEditorState> textEditorKey;
  final VoidCallback onTypographyPressed;

  @override
  Widget build(BuildContext context) {
    return ActionsToolbar(
      actions: [
        ToolbarMediaButton(
          delegate: QuillControllerHandler(textEditorController, ValueNotifier([])),
        ),
        ToolbarTypographyButton(
          textEditorController: textEditorController,
          onPressed: onTypographyPressed,
        ),
        ToolbarListButton(textEditorController: textEditorController, listType: Attribute.ul),
        ToolbarListQuoteButton(textEditorController: textEditorController),
        ToolbarMentionButton(
          textEditorController: textEditorController,
          textEditorKey: textEditorKey,
        ),
        ToolbarHashtagButton(
          textEditorController: textEditorController,
          textEditorKey: textEditorKey,
        ),
        ToolbarSeparatorButton(textEditorController: textEditorController),
      ],
    );
  }
}
