// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokenUtils {
  CreatorTokenUtils._();

  static Wallet? findBscWallet(List<Wallet> wallets) {
    return wallets.firstWhereOrNull(
      (w) =>
          w.network == TokenizedCommunitiesConstants.bscNetworkId ||
          w.network == TokenizedCommunitiesConstants.bscTestnetNetworkId,
    );
  }

  static bool hasBscWallet(UserMetadata? userMetadata) {
    return userMetadata?.wallets?.keys.any(
          (k) =>
              k == TokenizedCommunitiesConstants.bscNetworkId ||
              k == TokenizedCommunitiesConstants.bscTestnetNetworkId,
        ) ??
        false;
  }

  static Future<CoinsGroup?> deriveCreatorTokenCoinsGroup({
    required CommunityToken? token,
    required String externalAddress,
    required NetworkData network,
  }) async {
    if (token == null) return null;

    final balance = token.marketData.position?.amountValue ?? 0.0;
    final contractAddress = token.addresses.blockchain;

    if (contractAddress == null) return null;

    final coinData = CoinData(
      id: externalAddress,
      contractAddress: contractAddress,
      decimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
      iconUrl: token.imageUrl ?? '',
      name: token.title,
      network: network,
      priceUSD: token.marketData.priceUSD,
      abbreviation: token.title,
      symbolGroup: token.title,
      syncFrequency: const Duration(hours: 1),
    );

    final coinInWallet = CoinInWalletData(
      coin: coinData,
      amount: balance,
      rawAmount: balance.toString(),
      balanceUSD: balance * token.marketData.priceUSD,
    );

    return CoinsGroup(
      name: token.title,
      iconUrl: token.imageUrl ?? '',
      symbolGroup: token.title,
      abbreviation: token.title,
      coins: [coinInWallet],
      totalAmount: balance,
      totalBalanceUSD: balance * token.marketData.priceUSD,
    );
  }

  static String? tryExtractPubkeyFromExternalAddress(String externalAddress) {
    final parts = externalAddress.split(':');
    return parts.length == 3 ? parts[1] : null;
  }
}
