// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_code_block/text_editor_code_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_separator_block/text_editor_separator_block.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_placeholder_image_builder.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/unknown/text_editor_unknown_embed_builder.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

/// A lightweight version of TextEditorPreview used for measuring content height.
/// Uses placeholder widgets instead of real images to avoid expensive loading.
class ArticleContentMeasurer extends StatelessWidget {
  const ArticleContentMeasurer({
    required this.content,
    this.media,
    super.key,
  });

  final Delta content;
  final Map<String, MediaAttachment>? media;

  @override
  Widget build(BuildContext context) {
    final controller = QuillController(
      document: Document.fromDelta(content),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return QuillEditor.basic(
      controller: controller,
      config: QuillEditorConfig(
        floatingCursorDisabled: true,
        showCursor: false,
        scrollable: false,
        enableInteractiveSelection: false,
        customStyles: textEditorStyles(context),
        embedBuilders: [
          TextEditorPlaceholderImageBuilder(media: media),
          TextEditorSeparatorBuilder(readOnly: true),
          TextEditorCodeBuilder(readOnly: true),
        ],
        unknownEmbedBuilder: TextEditorUnknownEmbedBuilder(),
        disableClipboard: true,
      ),
    );
  }
}
