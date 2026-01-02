// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
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
    // Generate unique ID to distinguish duplicate mentions (ephemeral, not saved to Nostr)
    final mentionWithId = mentionData.copyWith(
      id: DateTime.now().toString(),
    );
    final embedData = mentionWithId.toJson();

    // Calculate final cursor position before making changes
    // After: embed (1) + space (1) = tagStart + 2
    final newCursorPosition = tagStart + 2;

    // Remove the '@...' placeholder text first, with selection at safe position
    controller
      ..replaceText(
        tagStart,
        tagLength,
        '',
        TextSelection.collapsed(offset: tagStart),
      )

      // Insert the mention embed (embed length counts as 1 in Quill)
      ..replaceText(
        tagStart,
        0,
        Embeddable(mentionEmbedKey, embedData),
        TextSelection.collapsed(offset: tagStart + 1),
      )

      // Insert visible space after the embed
      ..replaceText(
        tagStart + 1,
        0,
        ' ',
        TextSelection.collapsed(offset: newCursorPosition),
      );

    return newCursorPosition;
  }

  static String insertMentionAsText(
    QuillController controller,
    int tagStart,
    int tagLength,
    String pubkey,
    String username, {
    bool showMarketCap = false,
  }) {
    final encodedRef = ReplaceableEventReference(
      masterPubkey: pubkey,
      kind: UserMetadataEntity.kind,
    ).encode();

    final mentionText = '$mentionPrefix$username';

    // Build attributes - only set showMarketCapKey if author chose to show market cap
    // (i.e., market cap existed at insertion time)
    final attributes = {
      MentionAttribute.attributeKey: encodedRef,
      if (showMarketCap) MentionAttribute.showMarketCapKey: true,
    };

    // Use Delta to replace tag with mention text and attributes, then add space
    final replaceDelta = Delta()
      ..retain(tagStart)
      ..delete(tagLength)
      ..insert(mentionText, attributes)
      ..insert(' ');

    controller.compose(
      replaceDelta,
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

    // Generate unique ID if not present (ephemeral, not saved to Nostr)
    final mentionWithId =
        mentionData.id == null ? mentionData.copyWith(id: DateTime.now().toString()) : mentionData;

    controller
      ..replaceText(start, mentionTextLength, '', null)
      ..replaceText(start, 0, Embeddable(mentionEmbedKey, mentionWithId.toJson()), null);
  }

  // Converts a mention embed back to text with mention attribute.
  // Used when market cap is not available (for proper text editing behavior).
  // If showMarketCap=false, explicitly marks this mention as text-only (X button clicked).
  static void downgradeMentionEmbedToText(
    QuillController controller,
    int embedPosition,
    MentionEmbedData mentionData, {
    bool showMarketCap = true,
  }) {
    if (embedPosition < 0 || embedPosition >= controller.document.length) {
      return;
    }

    final encodedRef = ReplaceableEventReference(
      masterPubkey: mentionData.pubkey,
      kind: UserMetadataEntity.kind,
    ).encode();

    final mentionText = '$mentionPrefix${mentionData.username}';

    // Build attributes
    // Preserve showMarketCap intent: if true, set flag so it can upgrade back when market cap appears
    final attributes = {
      MentionAttribute.attributeKey: encodedRef,
      if (showMarketCap) MentionAttribute.showMarketCapKey: true,
      if (!showMarketCap) MentionAttribute.showMarketCapKey: false,
    };

    // Use Delta to replace embed with attributed text
    final replaceDelta = Delta()
      ..retain(embedPosition)
      ..delete(1) // Remove embed (length = 1)
      ..insert(mentionText, attributes);

    controller.compose(
      replaceDelta,
      TextSelection.collapsed(offset: embedPosition + mentionText.length),
      ChangeSource.local,
    );
  }

  // Downgrades a mention embed to text format (user clicked X button).
  // This persists the author's choice to NOT display with market cap.
  // The mention stays in the document but without showMarketCap flag.
  static void removeMentionEmbed(
    QuillController controller,
    Embed embedNode,
  ) {
    // Parse the embed node data to get mention info (includes unique ID)
    final nodeMentionData = _parseMentionDataFromNode(embedNode.value.data);
    if (nodeMentionData == null) {
      return;
    }

    // Find embed position by matching unique ID - works for duplicate mentions
    final embedOffset = _findEmbedOffsetInDelta(
      controller.document.toDelta(),
      nodeMentionData,
    );

    if (embedOffset != -1) {
      // Downgrade embed to text format and explicitly set showMarketCap: false
      // This ensures author's choice to not display with market cap is persisted
      downgradeMentionEmbedToText(
        controller,
        embedOffset,
        nodeMentionData,
        showMarketCap: false,
      );
    }
  }

  // Finds embed offset by matching unique ID in delta operations.
  // Each mention embed has a unique ID, so this works correctly even with
  // multiple mentions of the same user.
  static int _findEmbedOffsetInDelta(Delta delta, MentionEmbedData targetMentionData) {
    var currentIndex = 0;

    for (final operation in delta.operations) {
      final length = operation.length ?? 1;

      if (operation.isInsert && operation.data is Map<String, dynamic>) {
        final data = operation.data! as Map<String, dynamic>;
        if (data.containsKey(mentionEmbedKey)) {
          final opMentionData = MentionEmbedData.fromJson(
            Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
          );

          // Match by unique ID if both have IDs
          if (opMentionData.id != null &&
              targetMentionData.id != null &&
              opMentionData.id == targetMentionData.id) {
            return currentIndex;
          }

          // Fallback: If no IDs, match by pubkey+username (first occurrence)
          // This handles legacy embeds without IDs
          if (opMentionData.id == null &&
              targetMentionData.id == null &&
              opMentionData.pubkey == targetMentionData.pubkey &&
              opMentionData.username == targetMentionData.username) {
            return currentIndex;
          }
        }
      }
      currentIndex += length;
    }

    return -1;
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
