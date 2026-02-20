// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/bech32/bech32_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_protocol_identifier_type.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';

class MentionDeltaConverter {
  MentionDeltaConverter._();

  // Converts mention embeds to text with mention attributes for persistence.
  // Example: {'mention': {'pubkey': 'abc', 'username': 'user'}} -> '@user' with mention attribute
  static Delta convertEmbedsToAttributes(Delta input) {
    final out = Delta();
    final ops = input.toList();

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      final data = op.data;
      final attrs = op.attributes;

      // Unwrap Quill's embed format: {mentionEmbedKey: {...}} -> {...}
      final unwrappedData = _unwrapEmbedData(data);

      final mentionData = _parseMentionData(unwrappedData);

      // Only process pure embed operations (length == 1) to avoid capturing adjacent characters
      if (mentionData != null && (op.length ?? 1) == 1) {
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
          MentionAttribute.showMarketCapKey: true,
        };

        final mentionText = '$mentionPrefix${mentionData.username}';
        out.insert(mentionText, mergedAttrs);

        // Insert zero-width space in case if there's a next operation with content to prevent merging
        if (i + 1 < ops.length &&
            ops[i + 1].data is String &&
            (ops[i + 1].data! as String).trim().isNotEmpty) {
          out.insert('\u200B');
        }
      } else {
        out.push(op);
      }
    }

    return out;
  }

  // Converts mention attributes to embed operations for editor rendering.
  // Only converts if author chose to display with market cap (showMarketCap == true).
  // Reactive downgrade hook will handle removing embeds if market cap disappears.
  // Example: '@user' with mention attribute -> {'mention': {'pubkey': 'abc', 'username': 'user'}}
  static Delta convertAttributesToEmbeds(Delta input) {
    final out = Delta();

    for (final op in input.toList()) {
      final attrs = op.attributes;
      final data = op.data;

      // Skip zero-width space separator (structural only, not content)
      if (data is String && data == '\u200B') {
        continue;
      }

      final mentionAttr = attrs?[MentionAttribute.attributeKey];
      if (mentionAttr is String && data is String && data.startsWith(mentionPrefix)) {
        final username = data.substring(1);
        final pubkey = _tryDecodePubkey(mentionAttr);

        if (pubkey != null) {
          // Check if author wanted to display with market cap
          final showMarketCap = attrs?[MentionAttribute.showMarketCapKey] == true;

          if (showMarketCap) {
            // Author chose embed display - convert to embed
            // Market cap will be checked reactively by downgrade hook
            // Generate unique ID for each embed instance to handle duplicates
            final mentionData = MentionEmbedData(
              pubkey: pubkey,
              username: username,
              id: DateTime.now().toString(),
            );
            final embedData = {mentionEmbedKey: mentionData.toJson()};
            out.insert(embedData);
          } else {
            // Author chose text display or legacy mention (showMarketCap absent/false)
            // Keep as text with attribute
            out.push(op);
          }
        } else {
          // Failed to decode pubkey, keep as text with attribute
          out.push(op);
        }
      } else if (data is Map && data.containsKey(mentionEmbedKey)) {
        // Already an embed, keep as-is
        out.push(op);
      } else {
        // Not a mention with attribute, keep as-is
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
    return tryGetMentionPubkey(encoded);
  }

  /// Extracts pubkey from mention attribute or link value.
  /// Supports: ion:/nostr:nprofile, ion:/nostr:npub.
  static String? tryGetMentionPubkey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    // 1. ion:/nostr:nprofile
    if (IonConnectProtocolIdentifierTypeValidator.isProfileIdentifier(trimmed)) {
      try {
        return EventReference.fromEncoded(trimmed).masterPubkey;
      } catch (_) {
        return null;
      }
    }

    // 2. ion:/nostr:npub
    if (IonConnectProtocolIdentifierTypeValidator.isPublicKeyIdentifier(trimmed)) {
      return _npubPayloadToPubkey(IonConnectUriProtocolService().decode(trimmed));
    }

    return null;
  }

  static String? _npubPayloadToPubkey(String? payload) {
    const type = IonConnectProtocolIdentifierType.npub;
    if (payload == null || !payload.toLowerCase().startsWith(type.name)) {
      return null;
    }
    try {
      final decoded = IonConnectUriIdentifierService(
        bech32Service: Bech32Service(),
      ).decode(payload: payload);
      if (decoded.prefix == type) {
        return decoded.data;
      }
    } catch (_) {}
    return null;
  }
}
