// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/generated/assets.gen.dart';

enum InfoType {
  memo,
  walletAddress,
  networkFee,
  arrivalTime,
  transactionsInTier2Network,
  addressConfirmation,
  boostBalance,
  boostCost,
  boostBudget,
  boostAppleFee,
  boostTaxes;

  String getTitle(BuildContext context) {
    return switch (this) {
      InfoType.networkFee => context.i18n.wallet_network_fee,
      InfoType.arrivalTime => context.i18n.wallet_arrival_time,
      InfoType.transactionsInTier2Network => context.i18n.wallet_transactions_in_tier2_network,
      InfoType.addressConfirmation => context.i18n.wallet_address_confirmation,
      InfoType.memo => context.i18n.wallet_memo,
      InfoType.walletAddress => context.i18n.wallet_address,
      InfoType.boostBalance => context.i18n.boost_balance_title,
      InfoType.boostCost => context.i18n.boost_cost_title,
      InfoType.boostBudget => context.i18n.boost_budget_title,
      InfoType.boostAppleFee => context.i18n.boost_apple_fee_title,
      InfoType.boostTaxes => context.i18n.boost_taxes_title,
    };
  }

  String getDesc(BuildContext context) {
    return switch (this) {
      InfoType.networkFee => context.i18n.wallet_network_fee_info,
      InfoType.arrivalTime => context.i18n.wallet_arrival_time_info,
      InfoType.addressConfirmation => context.i18n.wallet_address_confirmation_info,
      InfoType.transactionsInTier2Network => context.i18n.wallet_transactions_in_tier2_network_info,
      InfoType.memo => context.i18n.wallet_memo_info,
      InfoType.walletAddress => context.i18n.wallet_address_info,
      InfoType.boostBalance => context.i18n.boost_balance_description,
      InfoType.boostCost => context.i18n.boost_cost_description,
      InfoType.boostBudget => context.i18n.boost_budget_description,
      InfoType.boostAppleFee => context.i18n.boost_apple_fee_description,
      InfoType.boostTaxes => context.i18n.boost_taxes_description,
    };
  }

  String get iconAsset {
    return switch (this) {
      InfoType.networkFee => Assets.svg.actionWalletNetworFee,
      InfoType.arrivalTime => Assets.svg.actionWalletArrivalTime,
      InfoType.addressConfirmation => Assets.svg.actionwalletinformation,
      InfoType.transactionsInTier2Network => Assets.svg.walletIconWalletTransactions,
      InfoType.memo => Assets.svg.actionWalletInformation,
      InfoType.walletAddress => Assets.svg.actionWalletAddress,
      InfoType.boostBalance => Assets.svg.actionPromotionBalance,
      InfoType.boostCost => Assets.svg.walletIconCost,
      InfoType.boostBudget => Assets.svg.walletIconBudget,
      InfoType.boostAppleFee => Assets.svg.actionPromotionFee,
      InfoType.boostTaxes => Assets.svg.actionPromotionTaxes,
    };
  }
}
