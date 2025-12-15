// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

// Hook that downgrades mention embeds without market cap when controller is created.
// For posts: processes immediately (document already loaded synchronously).
// For articles: call downgradeMentionEmbedsWithoutMarketCap manually after async document loading.
void useDowngradeMentionEmbedsWithoutMarketCap(QuillController? controller, WidgetRef ref) {
  useEffect(() {
    if (controller == null) return null;
    downgradeMentionEmbedsWithoutMarketCap(controller, ref);
    return null;
  }, [
    controller,
  ]);
}
