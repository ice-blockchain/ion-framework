// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coins_group_token_market_cap_provider.r.g.dart';

/// Returns the market cap for a cashtag suggestion **only** when it represents a
/// tokenized community token.
///
/// We treat a coin as tokenized-community when it has a non-empty
/// [CoinData.tokenizedCommunityExternalAddress].
@riverpod
double? coinsGroupTokenMarketCap(Ref ref, CoinsGroup group) {
  if (group.coins.isEmpty) return null;

  final externalAddress = group.coins.first.coin.tokenizedCommunityExternalAddress;
  if (externalAddress == null || externalAddress.isEmpty) return null;

  return ref.watch(
    tokenMarketInfoProvider(externalAddress).select(
      (state) => state.valueOrNull?.marketData.marketCap,
    ),
  );
}
