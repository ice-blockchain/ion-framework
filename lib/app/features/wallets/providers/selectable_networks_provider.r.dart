// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/contact_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selectable_networks_provider.r.g.dart';

@riverpod
Future<SelectableNetworkState> selectableNetworks(
  Ref ref, {
  required String symbolGroup,
  required String contactPubkey,
}) async {
  final coins = await ref.watch(
    syncedCoinsBySymbolGroupProvider(symbolGroup).future,
  );
  final contactAvailability = await ref.watch(
    contactWalletsAvailabilityProvider(contactPubkey: contactPubkey).future,
  );

  final enabled = <CoinInWalletData>[];
  final disabled = <CoinInWalletData>[];

  for (final coin in coins) {
    final networkId = coin.coin.network.id;
    final canReceive = contactAvailability.canReceiveOn(networkId);
    (canReceive ? enabled : disabled).add(coin);
  }

  final enabledNetworkIds = contactAvailability.hasPublicWallets
      ? contactAvailability.availableNetworkIds
      : coins.map((coin) => coin.coin.network.id).toSet();

  return SelectableNetworkState(
    coins: [...enabled, ...disabled],
    enabledNetworkIds: enabledNetworkIds,
  );
}

class SelectableNetworkState {
  const SelectableNetworkState({
    required this.coins,
    required this.enabledNetworkIds,
  });

  final List<CoinInWalletData> coins;
  final Set<String> enabledNetworkIds;

  bool isNetworkEnabled(NetworkData network) => enabledNetworkIds.contains(network.id);
}
