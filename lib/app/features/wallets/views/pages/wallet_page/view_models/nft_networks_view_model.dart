// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/networks/networks_comparator.r.dart';
import 'package:ion/app/features/wallets/domain/nfts/nft_network_filter_manager.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/services/command/command.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final nftNetworksViewModelProvider = Provider(
  (ref) {
    final filterService = ref.watch(nftNetworkFilterManagerProvider);
    final networksRepository = ref.watch(networksRepositoryProvider);
    final viewModel = NftNetworksViewModel(
      filterService: filterService,
      networksRepository: networksRepository,
    );

    ref.onDispose(viewModel._dispose);

    return viewModel;
  },
);

class NftNetworksViewModel {
  NftNetworksViewModel({
    required NftNetworkFilterManager filterService,
    required NetworksRepository networksRepository,
  })  : _filterService = filterService,
        _networksRepository = networksRepository,
        _networksComparator = NetworksComparator() {
    _initializeCommands();
  }

  final NftNetworkFilterManager _filterService;
  final NetworksRepository _networksRepository;
  final NetworksComparator _networksComparator;

  late final StateCommand<String> searchQueryCommand;
  late final Command<Set<String>, Set<NetworkData>> selectedNetworks;
  late final Command<void, List<NetworkData>> _allNetworksCommand;

  late final ValueListenable<List<NetworkData>> filteredNetworks;
  ValueListenable<Set<String>> get selectedNetworkIds => _filterService.selectedNetworksCommand;

  void _initializeCommands() {
    searchQueryCommand = stateCommand('');
    _allNetworksCommand = Command.createAsync(_loadAllNetworks, initialValue: []);

    filteredNetworks = _allNetworksCommand.combineLatest(
      searchQueryCommand,
      _filterNetworks,
    );

    selectedNetworks = Command.createAsync(_loadSelectedNetworks, initialValue: {});

    _filterService.selectedNetworksCommand.listen((networks, __) {
      selectedNetworks(networks);
    });

    _allNetworksCommand();
  }

  Future<List<NetworkData>> _loadAllNetworks(void _) async {
    return _networksRepository.getNftNetworks();
  }

  List<NetworkData> _filterNetworks(List<NetworkData> networks, String query) {
    final lowerCaseQuery = query.toLowerCase();
    return networks
        .where(
          (network) =>
              network.id.toLowerCase().contains(lowerCaseQuery) ||
              network.displayName.toLowerCase().contains(lowerCaseQuery),
        )
        .toList()
      ..sort(_networksComparator.compareNftNetworksByPopularity);
  }

  Future<Set<NetworkData>> _loadSelectedNetworks(Set<String> networks) async {
    return (await networks.map(_networksRepository.getById).wait).nonNulls.toSet();
  }

  void toggleNetwork(String network) {
    _filterService.toggleNetwork(network);
  }

  void unselectAllNetworks() {
    _filterService.selectedNetworksCommand({});
  }

  void _dispose() {
    searchQueryCommand.dispose();
    _allNetworksCommand.dispose();
  }
}
