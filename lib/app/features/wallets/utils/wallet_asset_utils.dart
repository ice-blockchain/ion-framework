// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;

ion.WalletAsset? getAssociatedWalletAsset(List<ion.WalletAsset> assets, CoinData? transferredCoin) {
  ion.WalletAsset? nativeAsset() => assets.firstWhereOrNull((asset) => asset.isNative);

  if (transferredCoin == null || transferredCoin.native) {
    return nativeAsset();
  }

  final contractAddress = transferredCoin.contractAddress;

  if (contractAddress.isNotEmpty) {
    final result = assets.firstWhereOrNull((asset) {
      final assetIdentifier = asset.maybeMap(
        erc20: (a) => a.contract,
        trc20: (a) => a.contract,
        trc10: (a) => a.tokenId,
        asa: (a) => a.assetId,
        spl: (a) => a.mint,
        spl2022: (a) => a.mint,
        sep41: (a) => a.issuer,
        tep74: (a) => a.master,
        aip21: (a) => a.metadata,
        unknown: (a) => a.contract,
        orElse: () => null,
      );
      return assetIdentifier != null && assetIdentifier == contractAddress;
    });

    if (result != null) {
      return result;
    }
  }

  final result = assets.firstWhereOrNull(
    (asset) => asset.symbol?.toLowerCase() == transferredCoin.abbreviation.toLowerCase(),
  );
  return result ?? nativeAsset();
}

({double amount, double balanceUSD, String rawAmount}) calculateBalanceFromAsset(
  ion.WalletAsset asset,
  CoinData coin,
) {
  final parsedBalance = double.tryParse(asset.balance) ?? 0;
  final amount = parsedBalance / pow(10, asset.decimals);
  final balanceUSD = amount * coin.priceUSD;
  return (amount: amount, balanceUSD: balanceUSD, rawAmount: asset.balance);
}
