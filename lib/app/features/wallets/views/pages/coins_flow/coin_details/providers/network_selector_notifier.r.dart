// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/network_selector_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_selector_notifier.r.g.dart';

@riverpod
class NetworkSelectorNotifier extends _$NetworkSelectorNotifier {
  @override
  Future<NetworkSelectorData?> build({required String symbolGroup}) async {
    final networksValue = ref
        .watch(
          syncedCoinsBySymbolGroupProvider(symbolGroup),
        )
        .valueOrNull;

    if (networksValue == null) return null;

    final networks = networksValue.map((e) => e.coin.network).toList();
    final wrappedNetworks = networks.map((e) => SelectedNetworkItem.network(network: e));
    final items = [
      if (wrappedNetworks.length > 1) SelectedNetworkItem.all(networks: networks),
      ...wrappedNetworks,
    ];

    // Get previous selection from state (safe with valueOrNull in async providers)
    final previousState = state.valueOrNull;
    final previousSelection = previousState?.selected;

    // Preserve previous selection if it's still valid, otherwise use first item
    final selectedItem = previousSelection != null && items.contains(previousSelection)
        ? previousSelection
        : items.first;

    return NetworkSelectorData(
      items: items,
      selected: selectedItem,
    );
  }

  set selected(SelectedNetworkItem item) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final canUpdate = item.map(
      network: (item) => currentState.items.contains(item),
      all: (_) => true,
    );

    if (canUpdate) {
      state = AsyncData(currentState.copyWith(selected: item));
    }
  }
}
