// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/domain/nfts/nft_network_filter_manager.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/services/command/command.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

typedef NftsState = ({List<NftData> allNfts, List<NftData> filteredNfts});

final walletNftsViewModelProvider = Provider(
  (ref) {
    final nftFilterService = ref.watch(nftNetworkFilterManagerProvider);

    final viewModel = WalletNftsViewModel(
      nftFilterService: nftFilterService,
    );

    ref.onDispose(viewModel._dispose);

    return viewModel;
  },
);

class WalletNftsViewModel {
  WalletNftsViewModel({
    required NftNetworkFilterManager nftFilterService,
  }) : _nftFilterService = nftFilterService {
    _initializeCommands();
    _setupCommandListeners();
  }

  final NftNetworkFilterManager _nftFilterService;

  late final StateCommand<List<NftData>> setNftsCommand;
  late final StateCommand<String> searchQueryCommand;
  late final ValueListenable<NftsState> filteredNfts;

  void _initializeCommands() {
    setNftsCommand = stateCommand([]);
    searchQueryCommand = stateCommand('');
    filteredNfts = setNftsCommand.combineLatest3(
      searchQueryCommand,
      _nftFilterService.selectedNetworksCommand,
      _filterNfts,
    );
  }

  void _setupCommandListeners() {
    setNftsCommand.listen((nfts, _) {
      _nftFilterService.availableNetworksCommand(nfts.map((nft) => nft.network.id).toSet());
    });
  }

  NftsState _filterNfts(List<NftData> nfts, String query, Set<String> selectedNetworks) {
    final filteredNfts = nfts
        .where(
          (nft) =>
              nft.symbol.toLowerCase().contains(query) || nft.name.toLowerCase().contains(query),
        )
        .where((nft) => selectedNetworks.isEmpty || selectedNetworks.contains(nft.network.id))
        .toList();

    return (allNfts: nfts, filteredNfts: filteredNfts);
  }

  void _dispose() {
    searchQueryCommand.dispose();
    setNftsCommand.dispose();
  }
}
