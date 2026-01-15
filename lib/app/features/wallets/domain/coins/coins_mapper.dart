// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion_identity;

class CoinsMapper {
  List<Coin> fromDtoToDb(Iterable<ion_identity.Coin> coins) => [
        for (final coin in coins)
          Coin(
            id: coin.id,
            contractAddress: coin.contractAddress,
            decimals: coin.decimals,
            iconURL: coin.iconURL,
            name: coin.name,
            networkId: coin.network,
            priceUSD: coin.priceUSD,
            symbol: coin.symbol,
            symbolGroup: coin.symbolGroup,
            syncFrequency: coin.syncFrequency,
            native: coin.native ?? false,
            prioritized: coin.prioritized ?? false,
            tokenizedCommunityExternalAddress: coin.tokenizedCommunityExternalAddress,
            tokenizedCommunityTokenType: coin.tokenizedCommunityTokenType,
          ),
      ];
}
