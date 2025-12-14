// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'trade_community_token_state.f.freezed.dart';

@freezed
class TradeCommunityTokenState with _$TradeCommunityTokenState {
  const factory TradeCommunityTokenState({
    @Default(CommunityTokenTradeMode.buy) CommunityTokenTradeMode mode,
    @Default(0) double amount,
    BigInt? quoteAmount,
    @Default(false) bool isQuoting,
    CoinData? selectedPaymentToken,
    CoinsGroup? paymentCoinsGroup,
    Wallet? targetWallet,
    NetworkData? targetNetwork,
    // Sell-specific fields
    @Default(0) double communityTokenBalance,
    CoinsGroup? communityTokenCoinsGroup,
  }) = _TradeCommunityTokenState;
}
