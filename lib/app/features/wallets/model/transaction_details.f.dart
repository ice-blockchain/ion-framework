// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_parser.dart';

part 'transaction_details.f.freezed.dart';

@freezed
class TransactionDetails with _$TransactionDetails {
  const factory TransactionDetails({
    required String txHash,
    required NetworkData network,
    required TransactionType type,
    required CryptoAssetToSendData assetData,
    required TransactionStatus status,
    required String walletViewId,
    required String? senderAddress,
    required String? receiverAddress,
    required String? walletViewName,
    required String? id,
    required String? participantPubkey,
    required DateTime? dateRequested,
    required DateTime? dateConfirmed,
    required DateTime? dateBroadcasted,
    required CoinData? nativeCoin,
    required NetworkFeeOption? networkFeeOption,
  }) = _TransactionDetails;

  factory TransactionDetails.fromTransactionData(
    TransactionData transaction, {
    CoinsGroup? coinsGroup,
    String? walletViewName,
  }) {
    final fee = transaction.fee;
    final nativeCoin = transaction.nativeCoin;
    final isFeeAvailable = fee != null && nativeCoin != null;
    final feeAmount = isFeeAvailable ? parseCryptoAmount(fee, nativeCoin.decimals) : null;

    return TransactionDetails(
      id: transaction.id,
      txHash: transaction.txHash,
      network: transaction.network,
      walletViewId: transaction.walletViewId,
      type: transaction.type,
      assetData: transaction.cryptoAsset.map(
        coin: (coin) {
          if (coinsGroup == null) {
            throw StateError('CoinsGroup is required for coin transactions');
          }
          return CryptoAssetToSendData.coin(
            coinsGroup: coinsGroup,
            amount: coin.amount,
            rawAmount: coin.rawAmount,
            amountUSD: coin.amountUSD,
          );
        },
        nft: (nft) => CryptoAssetToSendData.nft(nft: nft.nft),
        nftIdentifier: (nftIdentifier) => throw const FormatException(
          'NFT identifier should be resolved to full NFT data before creating TransactionDetails',
        ),
      ),
      walletViewName: walletViewName,
      senderAddress: transaction.senderWalletAddress,
      receiverAddress: transaction.receiverWalletAddress,
      participantPubkey: transaction.userPubkey,
      status: transaction.status,
      dateRequested: transaction.dateRequested,
      dateConfirmed: transaction.dateConfirmed,
      nativeCoin: transaction.nativeCoin,
      networkFeeOption: feeAmount != null && nativeCoin != null
          ? NetworkFeeOption(
              amount: feeAmount,
              symbol: nativeCoin.abbreviation,
              priceUSD: feeAmount * nativeCoin.priceUSD,
              type: null,
            )
          : null,
      dateBroadcasted: null,
    );
  }

  const TransactionDetails._();

  String get transactionExplorerUrl => network.getExplorerUrl(txHash);
}
