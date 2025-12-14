// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/services/mention_insertion_service.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/text_editor_mention_embed_builder.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';

// TODO: move this logic from Hook approach
//
// Processes mention embeds, downgrading those without market cap to text.
//
// Only processes when market cap provider has finished loading:
// - Has value and null → downgrade to text (editable)
// - Has value and non-null → keep as embed (shows market cap)
// - Still loading → keep as embed (will show when provider finishes)
void useProcessMentionEmbeds(QuillController? controller, WidgetRef ref) {
  useEffect(() {
    if (controller == null) return null;

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

          // Check if market cap provider has cached value
          final marketCapAsync = ref.read(userTokenMarketCapProvider(mentionData.pubkey));

          if (marketCapAsync.hasValue) {
            // Provider finished loading - check value
            if (marketCapAsync.value == null) {
              // Downgrade to text for proper editing behavior
              downgrades.add((position: currentOffset, data: mentionData));
            }
            // If value is not null, keep as embed - has market cap
          }
          // If still loading, keep as embed - will show when provider finishes
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
        message: 'Failed to process mention embeds',
      );
    }

    return null;
  }, [
    controller,
  ]);
}
