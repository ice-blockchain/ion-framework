// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';

part 'transaction_data.f.freezed.dart';

@freezed
class TransactionData with _$TransactionData {
  const factory TransactionData({
    required String txHash,
    required String walletViewId,
    required NetworkData network,
    required TransactionType type,
    required TransactionCryptoAsset cryptoAsset,
    String? id,
    String? fee,
    String? externalHash,
    CoinData? nativeCoin,
    DateTime? dateConfirmed,
    DateTime? dateRequested,
    DateTime? createdAtInRelay,
    String? senderWalletAddress,
    String? receiverWalletAddress,
    @Default(TransactionStatus.broadcasted) TransactionStatus status,
    String? userPubkey,
    String? memo,
    String? eventId,
    SwapStatus? swapStatus,
  }) = _TransactionData;
}
