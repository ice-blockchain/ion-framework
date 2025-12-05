// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';

class CoinsComparator {
  final _CoinPriority _prioritizer = _CoinPriority();

  int? _checkHardcodedPriority(String symbolGroupA, String symbolGroupB, String priorityCoin) {
    if (symbolGroupA == priorityCoin && symbolGroupB != priorityCoin) return -1;
    if (symbolGroupB == priorityCoin && symbolGroupA != priorityCoin) return 1;
    return null;
  }

  int _compare(
    double balanceA,
    double balanceB,
    String symbolGroupA,
    String symbolGroupB, {
    String? networkA,
    String? networkB,
    bool isNativeA = false,
    bool isNativeB = false,
    bool isPrioritizedA = false,
    bool isPrioritizedB = false,
  }) {
    // 0.1. ION always comes first, regardless of other conditions
    final firstCoinComparison =
        _checkHardcodedPriority(symbolGroupA, symbolGroupB, _CoinPriority._firstCoin);
    if (firstCoinComparison != null) return firstCoinComparison;

    // 0.2. ICE always comes second (after ION), regardless of other conditions
    final secondCoinComparison =
        _checkHardcodedPriority(symbolGroupA, symbolGroupB, _CoinPriority._secondCoin);
    if (secondCoinComparison != null) return secondCoinComparison;

    // 1. Compare by balanceUSD in descending order
    final balanceComparison = balanceB.compareTo(balanceA);
    if (balanceComparison != 0) return balanceComparison;

    // 2. If coin is prioritized, it should be displayed before other coins,
    if (isPrioritizedA && !isPrioritizedB) return -1;
    if (isPrioritizedB && !isPrioritizedA) return 1;

    // 3. Compare by priority list
    final aPriority = _prioritizer.getPriorityIndex(symbolGroupA);
    final bPriority = _prioritizer.getPriorityIndex(symbolGroupB);

    // If both are in priority list, compare their positions
    if (aPriority != -1 && bPriority != -1 && aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    // If only one is in priority list, it should come first
    if (aPriority != -1 && bPriority == -1) return -1;
    if (bPriority != -1 && aPriority == -1) return 1;

    // 4. Compare by symbolGroup
    final symbolGroupComparison = symbolGroupA.compareTo(symbolGroupB);
    if (symbolGroupComparison != 0) return symbolGroupComparison;

    // 5. If coin is native for network, it should be displayed before other coins,
    // sorted by network
    if (isNativeA && !isNativeB) return -1;
    if (isNativeB && !isNativeA) return 1;

    // 6. If symbolGroups are equal, compare by networks
    if (networkA != null && networkB != null) {
      return networkA.compareTo(networkB);
    }
    // If only one has network, it should come first
    if (networkA != null) return -1;
    if (networkB != null) return 1;

    return 0;
  }

  int compareGroups(CoinsGroup a, CoinsGroup b) {
    return _compare(
      a.totalBalanceUSD,
      b.totalBalanceUSD,
      a.symbolGroup,
      b.symbolGroup,
    );
  }

  int compareCoins(CoinInWalletData a, CoinInWalletData b) {
    return _compare(
      a.balanceUSD,
      b.balanceUSD,
      a.coin.symbolGroup,
      b.coin.symbolGroup,
      networkA: a.coin.network.displayName,
      networkB: b.coin.network.displayName,
      isNativeA: a.coin.native,
      isNativeB: b.coin.native,
      isPrioritizedA: a.coin.prioritized,
      isPrioritizedB: b.coin.prioritized,
    );
  }
}

class _CoinPriority {
  static const _firstCoin = 'ion';
  static const _secondCoin = 'ice';
  final _symbolGroupsPriorityList = const [
    _firstCoin,
    _secondCoin,
    'binancecoin', // Binance Coin
    'bitcoin', // Bitcoin
    'ethereum', // Ethereum
    'solana', // Solana
    'the-open-network', // Toncoin
    'dogecoin', // Dogecoin
    'litecoin', // Litecoin
    'stellar', // Stellar
    'tron', // Tron
    'ripple', // XRP
    'tezos', // Tezos
    'matic-network', // Polygon
    'polkadot', // Polkadot
    'optimism', // Optimism
    'cardano', // Cardano
    'algorand', // Algorand
    'kusama', // Kusama
    'avalanche-2', // Avalanche
    'kaspa', // Kaspa
    'arbitrum', // Arbitrum
    'token-s', // Token S
    'aptos', // Aptos
  ];

  int getPriorityIndex(String symbolGroup) {
    return _symbolGroupsPriorityList.indexOf(symbolGroup);
  }
}
