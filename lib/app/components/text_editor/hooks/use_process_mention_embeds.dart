// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

// Processes mention embeds and text mentions bidirectionally based on market cap availability.
// Downgrades embeds without market cap to text, upgrades text mentions with showMarketCap=true when market cap appears.
// Only processes when market cap provider has finished loading:
void processMentionEmbeds(QuillController controller, WidgetRef ref) {
  try {
    final delta = controller.document.toDelta();
    final downgrades = <({int position, MentionEmbedData data})>[];
    final upgrades = <({int position, String pubkey, String username, double marketCap})>[];

    // Scan document for both embeds and text mentions
    var currentOffset = 0;
    for (final op in delta.operations) {
      final length = op.length ?? 1;
      final data = op.data;
      final attrs = op.attributes;

      // Check for mention embeds
      if (data is Map && data.containsKey(mentionEmbedKey)) {
        final mentionData = MentionEmbedData.fromJson(
          Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
        );

        // Check market cap status for this mention
        final marketCapAsync = ref.read(userTokenMarketCapProvider(mentionData.pubkey));

        if (!marketCapAsync.hasValue) {
          // Still loading keep as embed
          currentOffset += length;
          continue;
        }

        if (marketCapAsync.value == null) {
          // Finished loading but no market cap - downgrade to text
          downgrades.add((position: currentOffset, data: mentionData));
        }
      }
      // Check for text mentions with showMarketCap flag
      else if (data is String &&
          attrs != null &&
          attrs.containsKey(MentionAttribute.attributeKey)) {
        final showMarketCap = attrs[MentionAttribute.showMarketCapKey] == true;
        if (showMarketCap && data.startsWith(mentionPrefix)) {
          try {
            final encodedRef = attrs[MentionAttribute.attributeKey] as String;
            final eventReference = EventReference.fromEncoded(encodedRef);
            final pubkey = eventReference.masterPubkey;
            final username = data.substring(1); // Remove @ prefix

            // Check market cap status
            final marketCapAsync = ref.read(userTokenMarketCapProvider(pubkey));

            if (marketCapAsync.hasValue && marketCapAsync.value != null) {
              // Market cap is available - upgrade to embed
              upgrades.add(
                (
                  position: currentOffset,
                  pubkey: pubkey,
                  username: username,
                  marketCap: marketCapAsync.value!,
                ),
              );
            }
          } catch (_) {
            // Skip invalid references
          }
        }
      }

      currentOffset += length;
    }

    // Downgrade embeds without market cap (in reverse order to maintain positions)
    if (downgrades.isNotEmpty) {
      for (final downgrade in downgrades.reversed) {
        try {
          MentionInsertionService.downgradeMentionEmbedToText(
            controller,
            downgrade.position,
            downgrade.data,
          );
        } catch (e, stackTrace) {
          // Log but continue with other downgrades
          // Position might be invalid if document was edited (rare edge case)
          Logger.error(
            e,
            stackTrace: stackTrace,
            message: 'Failed to downgrade mention embed at position ${downgrade.position}',
          );
        }
      }
    }

    // Upgrade text mentions with market cap (in reverse order to maintain positions)
    if (upgrades.isNotEmpty) {
      for (final upgrade in upgrades.reversed) {
        try {
          final mentionData = MentionEmbedData(
            pubkey: upgrade.pubkey,
            username: upgrade.username,
          );
          final mentionText = '$mentionPrefix${upgrade.username}';
          MentionInsertionService.upgradeMentionToEmbed(
            controller,
            upgrade.position,
            mentionText.length,
            mentionData,
            upgrade.marketCap,
          );
        } catch (e, stackTrace) {
          // Log but continue with other upgrades
          Logger.error(
            e,
            stackTrace: stackTrace,
            message: 'Failed to upgrade mention at position ${upgrade.position}',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: 'Failed to process mention embeds',
    );
  }
}

// Extracts mention pubkeys from a document delta.
// Returns list of unique pubkeys found in both mention embeds and text mentions with attributes.
List<String> _extractMentionPubkeys(Delta delta) {
  final pubkeys = <String>{};

  for (final op in delta.operations) {
    final data = op.data;
    final attrs = op.attributes;

    // Check for mention embeds
    if (data is Map && data.containsKey(mentionEmbedKey)) {
      try {
        final mentionData = MentionEmbedData.fromJson(
          Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
        );
        pubkeys.add(mentionData.pubkey);
      } catch (_) {
        // Skip invalid mention data
      }
    }
    // Check for text mentions with attributes
    else if (data is String && attrs != null && attrs.containsKey(MentionAttribute.attributeKey)) {
      try {
        final encodedRef = attrs[MentionAttribute.attributeKey] as String;
        final eventReference = EventReference.fromEncoded(encodedRef);
        pubkeys.add(eventReference.masterPubkey);
      } catch (_) {
        // Skip invalid references
      }
    }
  }

  return pubkeys.toList();
}

// Hook that processes mention embeds bidirectionally based on market cap availability.
// Watches market cap providers and:
// - Downgrades embeds without market cap to text
// - Upgrades text mentions with showMarketCap=true when market cap appears
// Works for both edit mode and preview mode (read-only controllers).
//
// [enabled]: If false, hook does nothing. Use this when mentions are rendered as text
// (e.g., replies) instead of embeds, so there's nothing to process.
void useProcessMentionEmbeds(
  QuillController? controller,
  WidgetRef ref, {
  bool enabled = true,
}) {
  // Store current pubkeys and only update when they actually change
  final mentionPubkeys = useState<List<String>>([]);

  // Guard to prevent feedback loops during processing
  final isProcessing = useRef(false);

  // Initialize and update pubkeys when document changes
  // Only updates if pubkeys actually changed (optimized)
  useEffect(
    () {
      if (!enabled || controller == null) return null;

      void updatePubkeys() {
        final delta = controller.document.toDelta();
        final newPubkeys = _extractMentionPubkeys(delta);
        final newPubkeysSet = newPubkeys.toSet();
        final currentPubkeysSet = mentionPubkeys.value.toSet();

        // Only update if pubkeys actually changed
        if (newPubkeysSet.length != currentPubkeysSet.length ||
            !newPubkeysSet.containsAll(currentPubkeysSet)) {
          mentionPubkeys.value = newPubkeys;
        }
      }

      // Initialize
      updatePubkeys();

      // Listen to document changes (only fires on document changes, not selection)
      final subscription = controller.document.changes.listen((_) {
        updatePubkeys();
      });

      return subscription.cancel;
    },
    [controller, enabled],
  );

  // Watch all market cap providers reactively
  final marketCapStates =
      mentionPubkeys.value.map((pubkey) => ref.watch(userTokenMarketCapProvider(pubkey))).toList();

  // Re-run processing when providers finish loading (reactive to provider changes)
  useEffect(
    () {
      if (!enabled || controller == null || mentionPubkeys.value.isEmpty) return null;

      // Skip if already processing (prevents feedback loops)
      if (isProcessing.value) return null;

      // Check if all providers finished loading
      final allLoaded = marketCapStates.every((state) => state.hasValue);
      if (allLoaded) {
        isProcessing.value = true;
        try {
          // Process both downgrades and upgrades
          processMentionEmbeds(controller, ref);
        } finally {
          isProcessing.value = false;
        }
      }
      return null;
    },
    [controller, marketCapStates, enabled],
  );
}
