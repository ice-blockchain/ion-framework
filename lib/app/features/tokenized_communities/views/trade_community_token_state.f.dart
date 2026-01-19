// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

part 'trade_community_token_state.f.freezed.dart';

@freezed
class TradeCommunityTokenState with _$TradeCommunityTokenState {
  const factory TradeCommunityTokenState({
    @Default(CommunityTokenTradeMode.buy) CommunityTokenTradeMode mode,
    @Default(0) double amount,
    PricingResponse? quotePricing,
    @Default(false) bool isQuoting,
    @Default(false) bool isPaymentTokenSelectable,
    CoinData? selectedPaymentToken,
    CoinsGroup? paymentCoinsGroup,
    Wallet? targetWallet,
    NetworkData? targetNetwork,
    @Default(true) bool shouldSendEvents,
    // Sell-specific fields
    @Default(0) double communityTokenBalance,
    CoinsGroup? communityTokenCoinsGroup,
    @Default(TokenizedCommunitiesConstants.defaultSlippagePercent) double slippage,
    @Default(false) bool shouldWaitSuggestedDetails,
    SuggestedTokenDetails? suggestedDetails,
  }) = _TradeCommunityTokenState;

  const TradeCommunityTokenState._();

  BigInt? get quoteAmount {
    final pricing = quotePricing;
    if (pricing == null) return null;
    return BigInt.tryParse(pricing.amount);
  }
}
