// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/model/network_selector_data.f.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_selector_notifier.r.g.dart';

@riverpod
class NetworkSelectorNotifier extends _$NetworkSelectorNotifier {
  @override
  NetworkSelectorData? build({required String symbolGroup}) {
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

    return NetworkSelectorData(
      items: items,
      selected: items.first,
    );
  }

  set selected(SelectedNetworkItem item) {
    final canUpdate = item.map(
      network: (item) => state?.items.contains(item) ?? false,
      all: (_) => true,
    );

    if (canUpdate) {
      state = state!.copyWith(selected: item);
    }
  }
}
