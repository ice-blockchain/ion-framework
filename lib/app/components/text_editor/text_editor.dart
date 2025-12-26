// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_code_block/text_editor_code_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_separator_block/text_editor_separator_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/unknown/text_editor_unknown_embed_builder.dart';
import 'package:ion/app/components/text_editor/custom_recognizer_builder.dart';
import 'package:ion/app/components/text_editor/utils/links_handler.dart';
import 'package:ion/app/components/text_editor/utils/mentions_hashtags_handler.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

class TextEditorKeys {
  const TextEditorKeys._();

  static GlobalKey<TextEditorState> createArticle() => GlobalKey<TextEditorState>();

  static GlobalKey<TextEditorState> replyInput() => GlobalKey<TextEditorState>();

  static GlobalKey<TextEditorState> createPost() => GlobalKey<TextEditorState>();

  static GlobalKey<TextEditorState> bioInput() => GlobalKey<TextEditorState>();
}

class TextEditor extends ConsumerStatefulWidget {
  const TextEditor(
    this.controller, {
    required GlobalKey<TextEditorState> key,
    this.placeholder,
    this.focusNode,
    this.autoFocus = true,
    this.scrollController,
    this.media,
    this.scrollable = false,
    this.authorPubkey,
  }) : super(key: key);

  final QuillController controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final bool autoFocus;
  final ScrollController? scrollController;
  final Map<String, MediaAttachment>? media;
  final bool scrollable;
  final String? authorPubkey;

  @override
  TextEditorState createState() => TextEditorState();
}

class TextEditorState extends ConsumerState<TextEditor> {
  late MentionsHashtagsHandler _mentionsHashtagsHandler;
  late LinksHandler _linksHandler;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();

  MentionsHashtagsHandler get mentionsHashtagsHandler => _mentionsHashtagsHandler;

  LinksHandler get linksHandler => _linksHandler;

  QuillController get quillController => widget.controller;

  @override
  void initState() {
    super.initState();
    _mentionsHashtagsHandler = MentionsHashtagsHandler(
      controller: widget.controller,
      focusNode: _focusNode,
      context: context,
      ref: ref,
    );

    _linksHandler = LinksHandler(
      controller: widget.controller,
      focusNode: _focusNode,
      context: context,
      ref: ref,
    );

    _mentionsHashtagsHandler.initialize();
    _linksHandler.initialize();
  }

  @override
  void dispose() {
    _mentionsHashtagsHandler.dispose();
    _linksHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: widget.controller,
      focusNode: _focusNode,
      scrollController: widget.scrollController,
      config: QuillEditorConfig(
        embedBuilders: [
          TextEditorSingleImageBuilder(media: widget.media, authorPubkey: widget.authorPubkey),
          TextEditorSeparatorBuilder(),
          TextEditorCodeBuilder(),
          const TextEditorMentionEmbedBuilder(),
        ],
        unknownEmbedBuilder: TextEditorUnknownEmbedBuilder(),
        autoFocus: widget.autoFocus,
        placeholder: widget.placeholder,
        customStyles: textEditorStyles(context),
        floatingCursorDisabled: true,
        customStyleBuilder: (attribute) => customTextStyleBuilder(attribute, context),
        customRecognizerBuilder: (attribute, leaf) => customRecognizerBuilder(
          context,
          attribute,
          isEditing: true,
        ),
        scrollable: widget.scrollable,
      ),
    );
  }
}
