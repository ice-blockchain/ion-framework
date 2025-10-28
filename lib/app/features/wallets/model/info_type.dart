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
  addressConfirmation;

  String getTitle(BuildContext context) {
    return switch (this) {
      InfoType.networkFee => context.i18n.wallet_network_fee,
      InfoType.arrivalTime => context.i18n.wallet_arrival_time,
      InfoType.transactionsInTier2Network => context.i18n.wallet_transactions_in_tier2_network,
      InfoType.addressConfirmation => context.i18n.wallet_address_confirmation,
      InfoType.memo => context.i18n.wallet_memo,
      InfoType.walletAddress => context.i18n.wallet_address,
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
    };
  }
}
