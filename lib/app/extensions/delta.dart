// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/utils/is_attributed_operation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

// General-purpose Delta extension for common operations
extension DeltaExt on Delta {
  bool get isSingleLinkOnly {
    return operations.length == 2 &&
        isAttributedOperation(operations.first, attribute: Attribute.link) &&
        operations.last.data == '\n';
  }

  bool get isBlank {
    if (isEmpty) return true;

    return operations.every((op) {
      final attrs = op.attributes;
      if (attrs != null &&
          (attrs.containsKey(Attribute.link.key) ||
              attrs.containsKey('text-editor-single-image'))) {
        return false;
      }
      return op.data.toString().trim().isEmpty;
    });
  }

  Delta get blank => isBlank ? this : Delta()
    ..insert('\n');
}

extension MentionDeltaExt on Delta {
  // Extracts only pubkeys from mentions (without flags)
  List<String> extractMentionPubkeys() {
    return extractMentionsWithFlags().map((m) => m.pubkey).toList();
  }

  // Extracts mention data including pubkey and showMarketCap flag
  // Handles both text mentions (with attributes) and embed mentions
  List<({String pubkey, bool showMarketCap})> extractMentionsWithFlags() {
    final mentions = <({String pubkey, bool showMarketCap})>[];
    for (final op in operations) {
      if (op.key == 'insert') {
        final data = op.data;
        final attrs = op.attributes;

        // Check for text mention with attribute
        if (attrs != null && attrs.containsKey(MentionAttribute.attributeKey)) {
          final encodedRef = attrs[MentionAttribute.attributeKey] as String;
          final eventReference = EventReference.fromEncoded(encodedRef);
          final showMarketCap = attrs[MentionAttribute.showMarketCapKey] == true;

          mentions.add(
            (
              pubkey: eventReference.masterPubkey,
              showMarketCap: showMarketCap,
            ),
          );
        }
        // Check for embed mention
        else if (data is Map) {
          const mentionKey = 'mention';
          if (data.containsKey(mentionKey)) {
            final mentionData = data[mentionKey];
            if (mentionData is Map) {
              final pubkey = mentionData['pubkey'] as String?;
              if (pubkey != null) {
                // Embeds always have showMarketCap=true (user chose to display with market cap)
                mentions.add(
                  (
                    pubkey: pubkey,
                    showMarketCap: true,
                  ),
                );
              }
            }
          }
        }
      }
    }
    return mentions;
  }

  // Iterate over all mentions in document order with symmetric extraction logic.
  // Ensures save and load flows process mentions identically (prevents divergence).
  // Callback receives (pubkey, showMarketCap) for each valid mention found.
  void forEachMention(void Function(String pubkey, {required bool showMarketCap}) callback) {
    for (final op in operations) {
      if (op.key == 'insert') {
        final data = op.data;
        final attrs = op.attributes;

        // Check for text mention with attribute
        if (attrs != null && attrs.containsKey(MentionAttribute.attributeKey)) {
          final encodedRef = attrs[MentionAttribute.attributeKey] as String;
          try {
            final eventReference = EventReference.fromEncoded(encodedRef);
            final pubkey = eventReference.masterPubkey;

            if (pubkey.isNotEmpty) {
              final showMarketCap = attrs[MentionAttribute.showMarketCapKey] == true;
              callback(pubkey, showMarketCap: showMarketCap);
            }
          } catch (_) {
            // Skip invalid references
          }
        }
        // Check for embed mention
        else if (data is Map) {
          const mentionKey = 'mention';
          if (data.containsKey(mentionKey)) {
            final mentionData = data[mentionKey];
            if (mentionData is Map) {
              final pubkey = mentionData['pubkey'] as String?;
              if (pubkey != null && pubkey.isNotEmpty) {
                // Embeds always have showMarketCap=true (user chose to display with market cap)
                callback(pubkey, showMarketCap: true);
              }
            }
          }
        }
      }
    }
  }
}
