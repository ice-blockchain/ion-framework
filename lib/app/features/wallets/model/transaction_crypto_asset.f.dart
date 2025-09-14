// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';

part 'transaction_crypto_asset.f.freezed.dart';

@freezed
sealed class TransactionCryptoAsset with _$TransactionCryptoAsset {
  const factory TransactionCryptoAsset.coin({
    required CoinData coin,
    @Default(0.0) double amount,
    @Default(0.0) double amountUSD,
    @Default('0') String rawAmount,
  }) = CoinTransactionAsset;

  const factory TransactionCryptoAsset.nft({
    required NftData nft,
  }) = NftTransactionAsset;

  const factory TransactionCryptoAsset.nftIdentifier({
    required NftIdentifier nftIdentifier,
    required NetworkData network,
  }) = NftIdentifierTransactionAsset;

  const factory TransactionCryptoAsset.undefinedCoin({
    required String contractAddress,
    @Default('0') String rawAmount,
  }) = UndefinedTransactionAsset;

  const TransactionCryptoAsset._();
}
