// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/network_data.f.dart';

enum NetworkSortType {
  nftPopularity,
}

class NetworkIds {
  const NetworkIds({
    required this.mainnetNetworkId,
    required this.testnetNetworkId,
  });

  final String mainnetNetworkId;
  final String testnetNetworkId;

  bool matches(NetworkData network) =>
      mainnetNetworkId == network.id || testnetNetworkId == network.id;
}

class NetworksComparator {
  NetworksComparator({required this.sortType}) : _prioritizer = NetworkPriority();

  final NetworkSortType sortType;
  final NetworkPriority _prioritizer;

  int _compare(NetworkData networkA, NetworkData networkB) {
    switch (sortType) {
      case NetworkSortType.nftPopularity:
        return _compareNftPopularity(networkA, networkB);
    }
  }

  int _compareNftPopularity(NetworkData networkA, NetworkData networkB) {
    const topNetwork = NetworkPriority._topNetwork;

    // 0. ION always comes first, regardless of other conditions
    final isNetworkATop = topNetwork.matches(networkA);
    final isNetworkBTop = topNetwork.matches(networkB);

    if (isNetworkATop && !isNetworkBTop) return -1;
    if (isNetworkBTop && !isNetworkATop) return 1;

    // 1. Compare by NFT popularity priority list using network IDs
    final aPriority = _prioritizer.getNftPopularityIndex(networkA.id);
    final bPriority = _prioritizer.getNftPopularityIndex(networkB.id);

    // If both are in priority list, compare their positions
    if (aPriority != -1 && bPriority != -1 && aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    // If only one is in priority list, it should come first
    if (aPriority != -1 && bPriority == -1) return -1;
    if (bPriority != -1 && aPriority == -1) return 1;

    // 2. Compare alphabetically by display name
    return networkA.displayName.compareTo(networkB.displayName);
  }

  int compareNetworks(NetworkData a, NetworkData b) {
    return _compare(a, b);
  }
}

class NetworkPriority {
  static const _topNetwork = NetworkIds(mainnetNetworkId: 'Ion', testnetNetworkId: 'IonTestnet');

  final _nftPopularityList = <NetworkIds>[
    _topNetwork,
    const NetworkIds(mainnetNetworkId: 'Ethereum', testnetNetworkId: 'EthereumSepolia'),
    const NetworkIds(mainnetNetworkId: 'Solana', testnetNetworkId: 'SolanaDevnet'),
    const NetworkIds(mainnetNetworkId: 'Bitcoin', testnetNetworkId: 'BitcoinSignet'),
    const NetworkIds(mainnetNetworkId: 'Polygon', testnetNetworkId: 'PolygonAmoy'),
    const NetworkIds(mainnetNetworkId: 'Bsc', testnetNetworkId: 'BscTestnet'),
    const NetworkIds(mainnetNetworkId: 'ArbitrumOne', testnetNetworkId: 'ArbitrumSepolia'),
    const NetworkIds(mainnetNetworkId: 'AvalancheC', testnetNetworkId: 'AvalancheCFuji'),
  ];

  int getNftPopularityIndex(String networkId) {
    final index = _nftPopularityList.indexWhere(
      (ids) => ids.mainnetNetworkId == networkId || ids.testnetNetworkId == networkId,
    );
    return index == -1 ? -1 : index;
  }
}
