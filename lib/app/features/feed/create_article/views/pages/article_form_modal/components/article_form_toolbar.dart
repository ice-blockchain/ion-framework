// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/components/article_main_toolbar.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/components/article_typography_toolbar.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';

class ArticleFormToolbar extends HookWidget {
  const ArticleFormToolbar({
    required this.textEditorController,
    required this.textEditorKey,
    super.key,
  });

  final QuillController textEditorController;
  final GlobalKey<TextEditorState> textEditorKey;

  @override
  Widget build(BuildContext context) {
    final isTypographyToolbarVisible = useState(false);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isTypographyToolbarVisible.value
          ? ArticleTypographyToolbar(
              textEditorController: textEditorController,
              onClosePressed: () {
                hideKeyboard(context);
                isTypographyToolbarVisible.value = false;
              },
            )
          : ArticleMainToolbar(
              textEditorController: textEditorController,
              textEditorKey: textEditorKey,
              onTypographyPressed: () {
                isTypographyToolbarVisible.value = true;
              },
            ),
    );
  }
}
