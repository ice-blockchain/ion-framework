// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';

class TradePaymentTokenGroupsService {
  const TradePaymentTokenGroupsService();

  List<CoinsGroup> build({
    required List<CoinData> supportedTokens,
    required WalletViewData walletView,
  }) {
    return supportedTokens.map((token) {
      final group = walletView.coinGroups.firstWhereOrNull(
        (g) => g.symbolGroup == token.symbolGroup,
      );

      final amount = group?.totalAmount ?? 0;
      final balanceUSD = group?.totalBalanceUSD ?? 0;

      return CoinsGroup(
        name: token.name,
        iconUrl: token.iconUrl,
        symbolGroup: token.symbolGroup,
        abbreviation: token.abbreviation,
        totalAmount: amount,
        totalBalanceUSD: balanceUSD,
        coins: [
          CoinInWalletData(
            coin: token,
            amount: amount,
            balanceUSD: balanceUSD,
          ),
        ],
      );
    }).toList();
  }
}
