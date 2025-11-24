// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar/actions_toolbar.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_buttons.dart';
import 'package:ion/app/services/keyboard/keyboard.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

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
        _KeyboardDismissingMediaButton(
          delegate: QuillControllerHandler(textEditorController, ValueNotifier([])),
        ),
        _KeyboardDismissingTypographyButton(
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

class _KeyboardDismissingMediaButton extends StatelessWidget {
  const _KeyboardDismissingMediaButton({
    required this.delegate,
  });

  final ToolbarMediaButtonDelegate delegate;

  @override
  Widget build(BuildContext context) {
    return ToolbarMediaButton(
      delegate: _KeyboardDismissingMediaButtonDelegate(
        delegate: delegate,
        context: context,
      ),
    );
  }
}

class _KeyboardDismissingMediaButtonDelegate extends ToolbarMediaButtonDelegate {
  _KeyboardDismissingMediaButtonDelegate({
    required this.delegate,
    required this.context,
  });

  final ToolbarMediaButtonDelegate delegate;
  final BuildContext context;

  @override
  ValueNotifier<List<MediaFile>> get attachedMediaNotifier => delegate.attachedMediaNotifier;

  @override
  void onMediaSelected(List<MediaFile>? mediaFiles) {
    hideKeyboard(context);
    delegate.onMediaSelected(mediaFiles);
  }

  @override
  void handleSelectedMedia(List<MediaFile> files) {
    delegate.handleSelectedMedia(files);
  }
}

class _KeyboardDismissingTypographyButton extends StatelessWidget {
  const _KeyboardDismissingTypographyButton({
    required this.textEditorController,
    required this.onPressed,
  });

  final QuillController textEditorController;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ToolbarTypographyButton(
      textEditorController: textEditorController,
      onPressed: () {
        hideKeyboard(context);
        onPressed();
      },
    );
  }
}
