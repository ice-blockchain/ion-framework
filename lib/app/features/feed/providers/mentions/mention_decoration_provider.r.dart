// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mention_decoration_provider.r.g.dart';

// Decorates mentions in Delta with market cap information when available.
//
// Appends formatted market cap to mention text (e.g., `@username ($formattedCap)`).
// Only decorates if market cap exists and text doesn't already contain `(`.
@riverpod
Delta decoratedMentionsWithMarketCap(
  Ref ref,
  Delta delta,
) {
  final out = Delta();

  for (final op in delta.toList()) {
    final data = op.data;
    final attrs = op.attributes;

    // Check if this operation is a mention (has MentionAttribute)
    final mentionAttr = attrs?[MentionAttribute.attributeKey];
    if (data is String && mentionAttr is String) {
      // Decode pubkey from encoded EventReference (mentionAttr contains encoded reference)
      String? pubkey;
      try {
        pubkey = EventReference.fromEncoded(mentionAttr).masterPubkey;
      } catch (_) {
        pubkey = null;
      }

      if (pubkey != null) {
        // Check if author wanted to display with market cap
        final showMarketCap = attrs?[MentionAttribute.showMarketCapKey] == true;

        if (showMarketCap) {
          final marketCapAsync = ref.watch(userTokenMarketCapProvider(pubkey));
          final marketCap = marketCapAsync.valueOrNull;

          // Only decorate if market cap exists and text doesn't already contain market cap
          if (marketCap != null && !data.contains('(')) {
            final formattedCap = MarketDataFormatter.formatCompactNumber(marketCap);
            out.insert('$data ($formattedCap)', attrs);
            continue;
          }
        }
      }
    }

    out.push(op);
  }

  return out;
}
