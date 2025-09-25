// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'networks_comparator.r.g.dart';

@riverpod
NetworksComparator networksComparator(Ref ref) => NetworksComparator();

abstract class NetworkSortStrategy {
  int compare(NetworkData a, NetworkData b);
}

class NftPopularitySortStrategy implements NetworkSortStrategy {
  final _nftPrioritizedList = <NetworkIds>[
    const NetworkIds(mainnetNetworkId: 'Ion', testnetNetworkId: 'IonTestnet'),
    const NetworkIds(mainnetNetworkId: 'Ethereum', testnetNetworkId: 'EthereumSepolia'),
    const NetworkIds(mainnetNetworkId: 'Solana', testnetNetworkId: 'SolanaDevnet'),
    const NetworkIds(mainnetNetworkId: 'Bitcoin', testnetNetworkId: 'BitcoinSignet'),
    const NetworkIds(mainnetNetworkId: 'Bsc', testnetNetworkId: 'BscTestnet'),
    const NetworkIds(mainnetNetworkId: 'Polygon', testnetNetworkId: 'PolygonAmoy'),
    const NetworkIds(mainnetNetworkId: 'ArbitrumOne', testnetNetworkId: 'ArbitrumSepolia'),
    const NetworkIds(mainnetNetworkId: 'AvalancheC', testnetNetworkId: 'AvalancheCFuji'),
  ];

  int _getNetworkPriorityIndex(String networkId) {
    final index = _nftPrioritizedList.indexWhere((ids) => ids.matches(networkId));
    return index == -1 ? _nftPrioritizedList.length : index;
  }

  @override
  int compare(NetworkData networkA, NetworkData networkB) {
    final aPriority = _getNetworkPriorityIndex(networkA.id);
    final bPriority = _getNetworkPriorityIndex(networkB.id);

    // Compare by priority index, then alphabetically for same priority
    return aPriority != bPriority
        ? aPriority.compareTo(bPriority)
        : networkA.displayName.compareTo(networkB.displayName);
  }
}

class NetworkIds {
  const NetworkIds({
    required this.mainnetNetworkId,
    required this.testnetNetworkId,
  });

  final String mainnetNetworkId;
  final String testnetNetworkId;

  bool matches(String networkId) => mainnetNetworkId == networkId || testnetNetworkId == networkId;
}

class NetworksComparator {
  NetworksComparator();

  final nftPopularitySortStrategy = NftPopularitySortStrategy();

  int compareNftNetworksByPopularity(NetworkData a, NetworkData b) =>
      nftPopularitySortStrategy.compare(a, b);
}
