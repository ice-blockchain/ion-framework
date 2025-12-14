// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/market_data_formatter.dart';

// Decorates mentions in Delta with market cap information when available.
//
// Appends formatted market cap to mention text (e.g., `@username ($formattedCap)`).
// Only decorates if market cap exists and text doesn't already contain `(`.
class MentionDecorationService {
  // Returns: Delta with market cap decoration applied to mentions
  static Delta decorateMentionsWithMarketCap(
    Delta delta,
    WidgetRef ref,
  ) {
    final out = Delta();

    for (final op in delta.toList()) {
      final data = op.data;
      final attrs = op.attributes;

      final mentionAttr = attrs?[MentionAttribute.attributeKey];
      if (data is String && mentionAttr is String) {
        String? pubkey;
        try {
          pubkey = EventReference.fromEncoded(mentionAttr).masterPubkey;
        } catch (_) {
          pubkey = null;
        }

        if (pubkey != null) {
          // This is a one-time decoration, not reactive, so no need for watch
          final marketCapAsync = ref.read(userTokenMarketCapProvider(pubkey));
          final marketCap = marketCapAsync.valueOrNull;

          if (marketCap != null && !data.contains('(')) {
            final formattedCap = MarketDataFormatter.formatCompactNumber(marketCap);
            out.insert('$data ($formattedCap)', attrs);
            continue;
          }
        }
      }

      out.push(op);
    }

    return out;
  }
}
