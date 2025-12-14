// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

/// Helper class to identify ICE/ION swap coins
class SwapCoinIdentifier {
  /// Checks if a coin is ICE BSC
  static bool isIceBsc(CoinsGroup coin, NetworkData network) {
    return coin.abbreviation.toUpperCase() == 'ICE' && network.isBsc;
  }

  /// Checks if a coin is ION BSC
  static bool isIonBsc(CoinsGroup coin, NetworkData network) {
    return coin.abbreviation.toUpperCase() == 'ION' && network.isBsc;
  }

  static bool isInternalCoinGroup(CoinsGroup coin) {
    return ['ION', 'ICE'].contains(coin.abbreviation.toUpperCase());
  }

  /// Checks if a coin is ION ION (ION token on Ion network)
  static bool isIonIon(CoinsGroup coin, NetworkData network) {
    return coin.abbreviation.toUpperCase() == 'ION' &&
        (network.id == 'Ion' || network.id == 'IonTestnet');
  }

  /// Checks if a coin is one of the special ICE/ION swap coins
  static bool isInternalCoin(CoinsGroup? coin, NetworkData? network) {
    if (coin == null || network == null) {
      return false;
    }
    return isIceBsc(coin, network) || isIonBsc(coin, network) || isIonIon(coin, network);
  }

  static bool isInternalNetwork(String id) {
    return ['Bsc', 'Ion'].contains(id);
  }

  static bool isEthNetwork(String id) {
    return 'Ethereum' == id;
  }

  static bool isIceCoinGroup(CoinsGroup coinGroup) {
    return coinGroup.abbreviation == 'ICE';
  }
}
