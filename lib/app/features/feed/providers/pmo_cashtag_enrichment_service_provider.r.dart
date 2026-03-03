// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/pmo_cashtag_enrichment_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pmo_cashtag_enrichment_service_provider.r.g.dart';

@Riverpod(keepAlive: true)
PmoCashtagEnrichmentService pmoCashtagEnrichmentService(Ref ref) {
  return PmoCashtagEnrichmentService(
    resolveTokenDefinitionAddress: (externalAddress) async {
      final cached = await ref.read(
        cachedTokenDefinitionProvider(externalAddress: externalAddress).future,
      );

      final definition = cached ??
          await ref.read(
            tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress).future,
          );

      return definition?.toEventReference().encode();
    },
  );
}
