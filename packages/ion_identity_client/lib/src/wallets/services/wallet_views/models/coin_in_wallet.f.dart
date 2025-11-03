// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_identity_client/src/coins/models/coin.f.dart';

part 'coin_in_wallet.f.freezed.dart';
part 'coin_in_wallet.f.g.dart';

@freezed
class CoinInWallet with _$CoinInWallet {
  factory CoinInWallet({
    required Coin coin,
    String? walletId,
  }) = _CoinInWallet;

  factory CoinInWallet.fromJson(Map<String, dynamic> json) => _$CoinInWalletFromJson(json);
}
