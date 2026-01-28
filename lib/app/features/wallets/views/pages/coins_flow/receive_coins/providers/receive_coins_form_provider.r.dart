// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/receive_coins_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receive_coins_form_provider.r.g.dart';

@Riverpod(keepAlive: true)
class ReceiveCoinsFormController extends _$ReceiveCoinsFormController {
  @override
  ReceiveCoinsData build() => const ReceiveCoinsData(
        address: null,
        selectedCoin: null,
        selectedNetwork: null,
      );

  void setCoin(CoinsGroup coin) => state = state.copyWith(
        selectedCoin: coin,
        selectedNetwork: null,
        address: null,
      );

  void setNetwork(NetworkData network) => state = state.copyWith(
        selectedNetwork: network,
        address: null,
      );

  void setWalletAddress(String address) => state = state.copyWith(address: address);
}
