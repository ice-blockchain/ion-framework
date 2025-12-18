// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

// Downgrades mention embeds without market cap to text for proper editing behavior.
// Only processes when market cap provider has finished loading:
void downgradeMentionEmbedsWithoutMarketCap(QuillController controller, WidgetRef ref) {
  try {
    final delta = controller.document.toDelta();
    final downgrades = <({int position, MentionEmbedData data})>[];

    // Scan document for mention embeds
    var currentOffset = 0;
    for (final op in delta.operations) {
      final length = op.length ?? 1;
      final data = op.data;

      if (data is Map && data.containsKey(mentionEmbedKey)) {
        final mentionData = MentionEmbedData.fromJson(
          Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
        );

        // Check market cap status for this mention
        final marketCapAsync = ref.read(userTokenMarketCapProvider(mentionData.pubkey));

        if (!marketCapAsync.hasValue) {
          // Still loading keep as embed
          continue;
        }

        if (marketCapAsync.value == null) {
          // Finished loading but no market cap - downgrade to text
          downgrades.add((position: currentOffset, data: mentionData));
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
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: 'Failed to downgrade mention embeds without market cap',
    );
  }
}

// Async version that waits for market cap providers to finish loading before downgrading.
// Use this when providers might not be loaded yet (e.g., article editing).
Future<void> downgradeMentionEmbedsWithoutMarketCapAsync(
  QuillController controller,
  WidgetRef ref,
) async {
  try {
    final delta = controller.document.toDelta();
    final mentions = <({int position, MentionEmbedData data, String pubkey})>[];

    // Scan document for mention embeds and collect their pubkeys
    var currentOffset = 0;
    for (final op in delta.operations) {
      final length = op.length ?? 1;
      final data = op.data;

      if (data is Map && data.containsKey(mentionEmbedKey)) {
        final mentionData = MentionEmbedData.fromJson(
          Map<String, dynamic>.from(data[mentionEmbedKey] as Map),
        );
        mentions.add(
          (
            position: currentOffset,
            data: mentionData,
            pubkey: mentionData.pubkey,
          ),
        );
      }

      currentOffset += length;
    }

    if (mentions.isEmpty) return;

    final marketCapResults = await Future.wait(
      mentions.map((mention) => ref.read(userTokenMarketCapProvider(mention.pubkey).future)),
    );

    // Collect downgrades (mentions without market cap)
    final downgrades = <({int position, MentionEmbedData data})>[];
    for (var i = 0; i < mentions.length; i++) {
      final marketCap = marketCapResults[i];
      if (marketCap == null) {
        downgrades.add((position: mentions[i].position, data: mentions[i].data));
      }
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
          Logger.error(
            e,
            stackTrace: stackTrace,
            message: 'Failed to downgrade mention embed at position ${downgrade.position}',
          );
        }
      }
    }
  } catch (e, stackTrace) {
    Logger.error(
      e,
      stackTrace: stackTrace,
      message: 'Failed to downgrade mention embeds without market cap',
    );
  }
}

// Extracts mention pubkeys from a document delta.
// Returns list of unique pubkeys found in mention embeds.
List<String> _extractMentionPubkeys(Delta delta) {
  final pubkeys = <String>{};

  for (final op in delta.operations) {
    final data = op.data;
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
  }

  return pubkeys.toList();
}

// Hook that downgrades mention embeds without market cap reactively.
// Watches market cap providers and downgrades when they finish loading.
// Works for both edit mode and preview mode (read-only controllers).
//
// [enabled]: If false, hook does nothing. Use this when mentions are rendered as text
// (e.g., replies) instead of embeds, so there's nothing to downgrade.
void useDowngradeMentionEmbedsWithoutMarketCap(
  QuillController? controller,
  WidgetRef ref, {
  bool enabled = true,
}) {
  // Extract mention pubkeys from document (memoized to avoid recalculation)
  final mentionPubkeys = useMemoized(
    () {
      if (controller == null || !enabled) return <String>[];
      final delta = controller.document.toDelta();
      return _extractMentionPubkeys(delta);
    },
    [controller?.document, enabled],
  );

  // Watch all market cap providers reactively
  final marketCapStates =
      mentionPubkeys.map((pubkey) => ref.watch(userTokenMarketCapProvider(pubkey))).toList();

  // Re-run downgrade when providers finish loading (reactive to provider changes)
  useEffect(() {
    if (!enabled || controller == null || mentionPubkeys.isEmpty) return null;

    // Check if all providers finished loading
    final allLoaded = marketCapStates.every((state) => state.hasValue);
    if (allLoaded) {
      // Call downgrade function (same logic for all modes)
      downgradeMentionEmbedsWithoutMarketCap(controller, ref);
    }
    return null;
  }, [controller, marketCapStates, enabled]);
}
