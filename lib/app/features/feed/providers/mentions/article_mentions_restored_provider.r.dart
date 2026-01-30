// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/markdown/mention_label_utils.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'article_mentions_restored_provider.r.g.dart';

@riverpod
Future<Delta> articleMentionsRestored(
  Ref ref, {
  required Delta delta,
  List<RelatedPubkey>? relatedPubkeys,
  EntityLabel? mentionMarketCapLabel,
  EntityLabel? cashtagMarketCapLabel,
}) async {
  final cashtagMarketCap = buildCashtagExternalAddressMapFromLabel(cashtagMarketCapLabel);

  // Fast path: no mentions and no cashtag market cap label
  if ((relatedPubkeys == null || relatedPubkeys.isEmpty) && cashtagMarketCap.isEmpty) {
    return delta;
  }

  var restored = delta;

  // Restore mentions if present
  if (relatedPubkeys != null && relatedPubkeys.isNotEmpty) {
    final usernameToPubkey = <String, String>{};
    final pubkeyInstanceShowMarketCap = buildInstanceMapFromLabel(mentionMarketCapLabel);

    for (final relatedPubkey in relatedPubkeys) {
      final pubkey = relatedPubkey.value;
      try {
        final userMetadata = await ref.read(
          userMetadataProvider(pubkey, network: false).future,
        );
        if (userMetadata != null && userMetadata.data.name.isNotEmpty) {
          usernameToPubkey[userMetadata.data.name] = pubkey;
        }
      } catch (_) {
        continue;
      }
    }

    restored = restoreMentions(
      restored,
      usernameToPubkey,
      pubkeyInstanceShowMarketCap: pubkeyInstanceShowMarketCap,
    );
  }

  // Ensure hashtag/cashtag attributes are applied, then restore cashtag market cap flags.
  final withMatches = processDeltaMatches(restored);
  return cashtagMarketCap.isEmpty
      ? withMatches
      : restoreCashtagsMarketCap(withMatches, cashtagMarketCap);
}
