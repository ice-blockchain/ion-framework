// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/generated/assets.gen.dart';

enum WalletTabType {
  coins,
  creatorTokens,
  nfts;

  CryptoAssetType get walletAssetType {
    return switch (this) {
      WalletTabType.coins => CryptoAssetType.coin,
      WalletTabType.nfts => CryptoAssetType.nft,
      WalletTabType.creatorTokens => CryptoAssetType.coin,
    };
  }

  String get emptyListAsset {
    return switch (this) {
      WalletTabType.coins => Assets.svg.walletIconWalletEmptycoins,
      WalletTabType.nfts => Assets.svg.categoriesNft,
      WalletTabType.creatorTokens => Assets.svg.walletIconWalletEmptycoins,
    };
  }

  String get bottomActionAsset {
    return switch (this) {
      WalletTabType.coins => Assets.svg.iconButtonManagecoin,
      WalletTabType.nfts => Assets.svg.iconPostAddanswer,
      WalletTabType.creatorTokens => Assets.svg.iconButtonManagecoin,
    };
  }

  String getEmptyListTitle(BuildContext context) {
    return switch (this) {
      WalletTabType.coins => context.i18n.wallet_empty_coins,
      WalletTabType.nfts => context.i18n.wallet_empty_nfts,
      WalletTabType.creatorTokens => context.i18n.wallet_empty_coins,
    };
  }

  String getBottomActionTitle(BuildContext context) {
    return switch (this) {
      WalletTabType.coins => context.i18n.wallet_manage_coins,
      WalletTabType.nfts => context.i18n.wallet_receive_nft,
      WalletTabType.creatorTokens => context.i18n.wallet_manage_coins,
    };
  }

  String getTitle(BuildContext context) {
    switch (this) {
      case WalletTabType.coins:
        return context.i18n.core_coins;
      case WalletTabType.nfts:
        return context.i18n.core_nfts;
      case WalletTabType.creatorTokens:
        return context.i18n.general_creator_tokens;
    }
  }
}
