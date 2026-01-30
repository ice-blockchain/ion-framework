// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/utils/cashtag_delta_converter.dart';
import 'package:ion/app/components/text_editor/utils/mention_delta_converter.dart';

// Bridge for converting embed types that need format conversion for storage.
//
// Orchestrates delta conversions at the data preparation layer (posting, replying, loading).
// Note: Not all embeds need conversion - images, code blocks, and separators are stored as embeds.
// Only mentions for now are converted to attributes for storage (text + attribute format).

class DeltaBridge {
  DeltaBridge._();

  // Normalizes delta to attribute format by converting embed types that need conversion.
  //
  // Used when saving/submitting content (posts, replies, edits).
  // Converts mention embeds to attributes. Other embeds (images, code blocks, etc.) remain as embeds.
  static Delta normalizeToAttributeFormat(Delta editorDelta) {
    return CashtagDeltaConverter.convertEmbedsToAttributes(
      MentionDeltaConverter.convertEmbedsToAttributes(editorDelta),
    );
  }

  // Normalizes delta to embed format by converting attribute-based formats back to embeds.
  //
  // Used when loading content into the editor (editing posts, viewing content).
  // Converts mention attributes to embeds. Other embeds remain unchanged.
  static Delta normalizeToEmbedFormat(Delta storageDelta) {
    final withMentions = MentionDeltaConverter.convertAttributesToEmbeds(storageDelta);
    return CashtagDeltaConverter.convertAttributesToEmbeds(withMentions);
  }
}
