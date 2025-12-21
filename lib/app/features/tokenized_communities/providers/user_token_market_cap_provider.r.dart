// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_token_market_cap_provider.r.g.dart';

@riverpod
Future<double?> userTokenMarketCap(Ref ref, String pubkey) async {
  final userMetadata = await ref.read(
    userMetadataProvider(pubkey, network: false).future,
  );
  if (userMetadata == null) return null;

  // Check if entity has token before requesting analytics
  final eventReference = userMetadata.toEventReference();
  final hasToken = await ref.watch(
    ionConnectEntityHasTokenProvider(
      eventReference: eventReference,
    ).future,
  );
  if (!hasToken) return null;

  final eventReferenceString = eventReference.toString();
  final tokenInfo = await ref.watch(
    tokenMarketInfoProvider(eventReferenceString).future,
  );

  final marketCap = tokenInfo?.marketData.marketCap;

  return marketCap;
}
