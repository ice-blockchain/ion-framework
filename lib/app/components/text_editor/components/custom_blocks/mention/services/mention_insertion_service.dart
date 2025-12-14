// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

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

  static String insertMentionAsText(
    QuillController controller,
    int tagStart,
    int tagLength,
    String pubkey,
    String username,
  ) {
    final encodedRef = ReplaceableEventReference(
      masterPubkey: pubkey,
      kind: UserMetadataEntity.kind,
    ).encode();

    final mentionText = '$mentionPrefix$username';

    controller
      ..replaceText(tagStart, tagLength, mentionText, null)
      ..formatText(
        tagStart,
        mentionText.length,
        MentionAttribute.withValue(encodedRef),
      )
      ..replaceText(tagStart + mentionText.length, 0, ' ', null)
      ..updateSelection(
        TextSelection.collapsed(offset: tagStart + mentionText.length + 1),
        ChangeSource.local,
      );

    return mentionText;
  }

  // Replaces the text mention (with mention attribute) with an embed widget.
  // Validates document state and text match before replacing.
  static void upgradeMentionToEmbed(
    QuillController controller,
    int start,
    int mentionTextLength,
    MentionEmbedData mentionData,
    double marketCap,
  ) {
    final end = start + mentionTextLength;
    if (start < 0 || end > controller.document.length) {
      return;
    }

    // Verify text matches before replacing (prevents replacing wrong text if document was edited)
    final documentText = controller.document.toPlainText();
    final textAtPosition = documentText.substring(start, end);
    if (textAtPosition != '$mentionPrefix${mentionData.username}') {
      return;
    }

    controller
      ..replaceText(start, mentionTextLength, '', null)
      ..replaceText(start, 0, Embeddable(mentionEmbedKey, mentionData.toJson()), null);
  }

  // Converts a mention embed back to text with mention attribute.
  // Used when market cap is not available (for proper text editing behavior).
  static void downgradeMentionEmbedToText(
    QuillController controller,
    int embedPosition,
    MentionEmbedData mentionData,
  ) {
    if (embedPosition < 0 || embedPosition >= controller.document.length) {
      return;
    }

    final encodedRef = ReplaceableEventReference(
      masterPubkey: mentionData.pubkey,
      kind: UserMetadataEntity.kind,
    ).encode();

    final mentionText = '$mentionPrefix${mentionData.username}';

    // Replace embed (length = 1) with text
    controller
      ..replaceText(embedPosition, 1, mentionText, null)
      ..formatText(
        embedPosition,
        mentionText.length,
        MentionAttribute.withValue(encodedRef),
      );
  }

  // Removes a mention embed from the document.
  // Finds the embed position and deletes it along with any trailing space.
  static void removeMentionEmbed(
    QuillController controller,
    Embed embedNode,
  ) {
    // Parse the embed node data to get mention info
    final nodeMentionData = _parseMentionDataFromNode(embedNode.value.data);
    if (nodeMentionData == null) return;

    final delta = controller.document.toDelta();
    var embedIndex = -1; // Will store the position of the embed we're looking for
    var currentIndex = 0; // Tracks our position as we iterate through operations

    // Find the position of the embed in the document
    for (final operation in delta.operations) {
      final length = operation.length ?? 1;

      if (operation.isInsert && operation.data is Map<String, dynamic>) {
        final data = operation.data! as Map<String, dynamic>;
        if (data.containsKey(mentionEmbedKey)) {
          // Parse the mention data from delta operation
          final opMentionData = MentionEmbedData.fromJson(
            Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
          );

          // Check if this is the embed we're looking for by comparing pubkey and username
          if (opMentionData.pubkey == nodeMentionData.pubkey &&
              opMentionData.username == nodeMentionData.username) {
            embedIndex = currentIndex;
            break;
          }
        }
      }
      currentIndex += length;
    }

    if (embedIndex != -1) {
      // Delete the embed (length 1) and check for trailing space
      var deleteLength = 1;

      // Check if there's a trailing space after the embed
      if (embedIndex + 1 < controller.document.length &&
          controller.document.toPlainText()[embedIndex + 1] == ' ') {
        deleteLength = 2; // Delete embed + space
      }

      controller
        ..replaceText(embedIndex, deleteLength, '', null)

        // Update cursor position to where the embed was
        ..updateSelection(
          TextSelection.collapsed(offset: embedIndex),
          ChangeSource.local,
        );
    }
  }

  // Helper to parse mention data from embed node value data
  static MentionEmbedData? _parseMentionDataFromNode(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return MentionEmbedData.fromJson(data);
      }
    } catch (_) {
      // Invalid data
    }
    return null;
  }
}
