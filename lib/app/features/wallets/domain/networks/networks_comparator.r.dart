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

  int _getNftPopularityIndex(String networkId) {
    final index = _nftPopularityList.indexWhere(
      (ids) => ids.mainnetNetworkId == networkId || ids.testnetNetworkId == networkId,
    );
    return index == -1 ? -1 : index;
  }

  @override
  int compare(NetworkData networkA, NetworkData networkB) {
    // 0. ION always comes first, regardless of other conditions
    final isNetworkATop = _topNetwork.matches(networkA);
    final isNetworkBTop = _topNetwork.matches(networkB);

    if (isNetworkATop && !isNetworkBTop) return -1;
    if (isNetworkBTop && !isNetworkATop) return 1;

    // 1. Compare by NFT popularity priority list using network IDs
    final aPriority = _getNftPopularityIndex(networkA.id);
    final bPriority = _getNftPopularityIndex(networkB.id);

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
  NetworksComparator();

  final nftPopularitySortStrategy = NftPopularitySortStrategy();

  int compareNftNetworksByPopularity(NetworkData a, NetworkData b) =>
      nftPopularitySortStrategy.compare(a, b);
}
