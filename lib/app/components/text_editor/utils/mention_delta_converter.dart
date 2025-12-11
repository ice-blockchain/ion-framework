// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

class MentionDeltaConverter {
  MentionDeltaConverter._();

  // Converts mention embeds to text with mention attributes for persistence.
  // Example: {'mention': {'pubkey': 'abc', 'username': 'user'}} -> '@user' with mention attribute
  static Delta convertEmbedsToAttributes(Delta input) {
    final out = Delta();

    for (final op in input.toList()) {
      final data = op.data;
      final attrs = op.attributes;

      // Unwrap Quill's embed format: {mentionEmbedKey: {...}} -> {...}
      final unwrappedData = _unwrapEmbedData(data);

      final mentionData = _parseMentionData(unwrappedData);

      if (mentionData != null) {
        // Fall back to plain text if no pubkey is present.
        if (mentionData.pubkey.isEmpty) {
          out.insert('$mentionPrefix${mentionData.username}', attrs);
          continue;
        }

        final encodedRef = ReplaceableEventReference(
          masterPubkey: mentionData.pubkey,
          kind: UserMetadataEntity.kind,
        ).encode();

        final mergedAttrs = {
          ...?attrs,
          MentionAttribute.attributeKey: encodedRef,
        };

        out.insert('$mentionPrefix${mentionData.username}', mergedAttrs);
      } else {
        out.push(op);
      }
    }

    return out;
  }

  // Converts mention attributes to embed operations for editor rendering.
  // Example: '@user' with mention attribute -> {'mention': {'pubkey': 'abc', 'username': 'user'}}
  static Delta convertAttributesToEmbeds(Delta input) {
    final out = Delta();

    for (final op in input.toList()) {
      final attrs = op.attributes;
      final data = op.data;

      final mentionAttr = attrs?[MentionAttribute.attributeKey];
      if (mentionAttr is String && data is String && data.startsWith(mentionPrefix)) {
        final username = data.substring(1);
        final pubkey = _tryDecodePubkey(mentionAttr);

        if (pubkey != null) {
          final mentionData = MentionEmbedData(pubkey: pubkey, username: username);
          out.insert({mentionEmbedKey: mentionData.toJson()});
        } else {
          out.push(op);
        }
      } else {
        out.push(op);
      }
    }

    return out;
  }

  static dynamic _unwrapEmbedData(dynamic data) {
    if (data is Map && data.containsKey(mentionEmbedKey) && data.length == 1) {
      return data[mentionEmbedKey];
    }
    return data;
  }

  static MentionEmbedData? _parseMentionData(dynamic data) {
    try {
      if (data is Map) {
        return MentionEmbedData.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Invalid data, return null
    }
    return null;
  }

  static String? _tryDecodePubkey(String encoded) {
    try {
      return EventReference.fromEncoded(encoded).masterPubkey;
    } catch (_) {
      return null;
    }
  }
}
