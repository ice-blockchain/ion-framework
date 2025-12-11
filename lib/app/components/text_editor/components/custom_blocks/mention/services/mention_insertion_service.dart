// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';

// Service for inserting mention embeds into Quill documents.
class MentionInsertionService {
  MentionInsertionService._();

  static int insertMention(
    QuillController controller,
    int tagStart,
    int tagLength,
    MentionEmbedData mentionData,
  ) {
    final embedData = mentionData.toJson();

    // Remove the '@...' placeholder text
    controller
      ..replaceText(tagStart, tagLength, '', null)

      // Insert the mention embed (embed length counts as 1 in Quill)
      ..replaceText(tagStart, 0, Embeddable(mentionEmbedKey, embedData), null)

      // Add trailing space after the embed
      ..replaceText(tagStart + 1, 0, ' ', null);

    // Update cursor position: after embed (1) + space (1) = tagStart + 2
    final newCursorPosition = tagStart + 2;
    controller.updateSelection(
      TextSelection.collapsed(offset: newCursorPosition),
      ChangeSource.local,
    );

    return newCursorPosition;
  }
}
