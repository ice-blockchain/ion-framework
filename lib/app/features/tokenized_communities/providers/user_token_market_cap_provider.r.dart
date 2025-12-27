// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_token_market_cap_provider.r.g.dart';

@riverpod
double? userTokenMarketCap(Ref ref, String masterPubkey) {
  final eventReference = ReplaceableEventReference(
    masterPubkey: masterPubkey,
    kind: UserMetadataEntity.kind,
  );

  final externalAddress = eventReference.toString();

  return ref.watch(
    tokenMarketInfoProvider(externalAddress, eventReference: eventReference)
        .select((AsyncValue<CommunityToken?> state) => state.valueOrNull?.marketData.marketCap),
  );
}
