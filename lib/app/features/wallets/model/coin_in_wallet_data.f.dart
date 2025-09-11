// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';

part 'coin_in_wallet_data.f.freezed.dart';

@freezed
class CoinInWalletData with _$CoinInWalletData {
  const factory CoinInWalletData({
    required CoinData coin,
    @Default(0) double amount, // after converting by (amount / 10^decimal)
    @Default('0') String rawAmount, // initial balance value
    @Default(0) double balanceUSD,
    String? walletId, // real wallet, not wallet view. Can be null if wallet wasn't created.
    String? walletAddress,
    // contract address, that was specified directly in the wallet view
    // and it is not equal to the coin contract address
    String? originContractAddress,
  }) = _CoinInWalletData;

  const CoinInWalletData._();
}
