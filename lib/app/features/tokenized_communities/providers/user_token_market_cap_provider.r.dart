// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_token_market_cap_provider.r.g.dart';

@riverpod
Future<double?> userTokenMarketCap(Ref ref, String pubkey) async {
  final userMetadata = await ref.watch(
    userMetadataProvider(pubkey, network: false).future,
  );
  if (userMetadata == null) return null;

  final externalAddress = userMetadata.externalAddress;
  // TODO: move to extension
  // Strip the 'a' prefix for API calls (prefix is only for blockchain operations)
  final apiAddress = externalAddress.substring(1);
  final tokenInfo = await ref.watch(tokenMarketInfoProvider(apiAddress).future);
  return tokenInfo?.marketData.marketCap;
}
