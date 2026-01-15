// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/generated/assets.gen.dart';

enum WalletTabType {
  coins,
  nfts;

  CryptoAssetType get walletAssetType {
    return switch (this) {
      WalletTabType.coins => CryptoAssetType.coin,
      WalletTabType.nfts => CryptoAssetType.nft,
    };
  }

  String get emptyListAsset {
    return switch (this) {
      WalletTabType.coins => Assets.svg.walletIconWalletEmptycoins,
      WalletTabType.nfts => Assets.svg.categoriesNft,
    };
  }

  String get bottomActionAsset {
    return switch (this) {
      WalletTabType.coins => Assets.svg.iconButtonManagecoin,
      WalletTabType.nfts => Assets.svg.iconPostAddanswer,
    };
  }

  String getEmptyListTitle(BuildContext context) {
    return switch (this) {
      WalletTabType.coins => context.i18n.wallet_empty_coins,
      WalletTabType.nfts => context.i18n.wallet_empty_nfts,
    };
  }

  String getBottomActionTitle(BuildContext context) {
    return switch (this) {
      WalletTabType.coins => context.i18n.wallet_manage_coins,
      WalletTabType.nfts => context.i18n.wallet_receive_nft,
    };
  }

  String getTitle(BuildContext context) {
    switch (this) {
      case WalletTabType.coins:
        return context.i18n.core_coins;
      case WalletTabType.nfts:
        return context.i18n.core_nfts;
    }
  }
}
