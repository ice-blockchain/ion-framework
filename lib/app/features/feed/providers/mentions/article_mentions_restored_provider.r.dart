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
}) async {
  // If no mentions, return delta as-is
  if (relatedPubkeys == null || relatedPubkeys.isEmpty) {
    return delta;
  }

  // Build username → pubkey map (async lookups)
  final usernameToPubkey = <String, String>{};

  // Convert EntityLabel to restore format using shared utility
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

  // Restore mentions using username lookup
  return restoreMentions(
    delta,
    usernameToPubkey,
    pubkeyInstanceShowMarketCap: pubkeyInstanceShowMarketCap,
  );
}
