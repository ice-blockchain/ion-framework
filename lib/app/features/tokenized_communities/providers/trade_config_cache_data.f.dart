// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion_identity_client/ion_identity.dart';

part 'trade_config_cache_data.f.freezed.dart';

@freezed
class TradeConfigCacheData with _$TradeConfigCacheData {
  const factory TradeConfigCacheData({
    required CoinData selectedPaymentToken,
    required CoinsGroup paymentCoinsGroup,
    Wallet? targetWallet,
    NetworkData? targetNetwork,
  }) = _TradeConfigCacheData;
}
