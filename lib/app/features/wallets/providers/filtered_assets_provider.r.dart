// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/riverpod.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/app/features/wallets/model/manage_coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:ion/app/features/wallets/providers/contact_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filtered_assets_provider.r.g.dart';

const apiCallDelay = Duration(milliseconds: 500);

@Riverpod(keepAlive: true)
class WalletSearchQueryController extends _$WalletSearchQueryController {
  @override
  String build(CryptoAssetType assetType) => '';

  set query(String query) => state = query;
}

@riverpod
class FilteredCoinsNotifier extends _$FilteredCoinsNotifier {
  @override
  Future<List<CoinsGroup>> build() async {
    final manageCoinsNotifier = ref.watch(manageCoinsNotifierProvider);
    final coins = manageCoinsNotifier.value;

    final coinGroupsInWallet = await ref.watch(coinsInWalletProvider.future);

    final searchQueryListener = ref.listen<String>(
      walletSearchQueryControllerProvider(CryptoAssetType.coin),
      (_, next) => search(next),
    );

    ref.onDispose(searchQueryListener.close);

    if (coins == null || !coins.values.any((group) => group.isUpdating)) {
      return coinGroupsInWallet;
    }

    final updatingGroups =
        coins.values.where((group) => group.isUpdating).map((group) => group.coinsGroup).toList();

    final filteredCoinGroups = coinGroupsInWallet.where(
      (group) => !_isBeingDeleted(group, coins),
    );

    return [...filteredCoinGroups, ...updatingGroups];
  }

  bool _isBeingDeleted(CoinsGroup group, Map<String, ManageCoinsGroup>? selectedCoins) {
    final manageGroup = selectedCoins?[group.symbolGroup];
    return (manageGroup?.isUpdating ?? false) && !(manageGroup?.isSelected ?? false);
  }

  Future<void> search(String query) async {
    await ref.debounce();
    final coinGroups = await ref.watch(coinsInWalletProvider.future);
    final manageCoinsNotifier = ref.watch(manageCoinsNotifierProvider);

    final newlyAddedGroups = manageCoinsNotifier.value?.values
            .where((group) => group.isUpdating)
            .map((group) => group.coinsGroup)
            .toList() ??
        [];

    final allCoins = [...coinGroups, ...newlyAddedGroups];

    final filteredCoins = _filterCoins(allCoins, query);
    state = AsyncData(filteredCoins);
  }
}

List<CoinsGroup> _filterCoins(List<CoinsGroup> coins, String query) {
  if (query.isEmpty) {
    return coins;
  }
  return coins
      .where(
        (group) =>
            group.name.toLowerCase().contains(query) ||
            group.abbreviation.toLowerCase().contains(query),
      )
      .toList();
}

@riverpod
Future<SelectableCoinsUiState> selectableFilteredCoins(
  Ref ref, {
  String? contactPubkey,
}) async {
  final filteredGroups = await ref.watch(filteredCoinsNotifierProvider.future);

  final allEnabledGroups = filteredGroups.map((group) => group.symbolGroup);

  if (contactPubkey == null) {
    return SelectableCoinsUiState(
      groups: filteredGroups,
      enabledSymbolGroups: allEnabledGroups.toSet(),
    );
  }

  final contactAvailability = await ref.watch(
    contactWalletsAvailabilityProvider(contactPubkey: contactPubkey).future,
  );

  final enabled = <CoinsGroup>[];
  final disabled = <CoinsGroup>[];

  for (final group in filteredGroups) {
    final canReceive = !contactAvailability.hasPublicWallets ||
        group.coins.any(
          (coin) => contactAvailability.availableNetworkIds.contains(coin.coin.network.id),
        );

    (canReceive ? enabled : disabled).add(group);
  }

  return SelectableCoinsUiState(
    groups: [...enabled, ...disabled],
    enabledSymbolGroups: contactAvailability.hasPublicWallets
        ? enabled.map((group) => group.symbolGroup).toSet()
        : allEnabledGroups.toSet(),
  );
}

class SelectableCoinsUiState {
  const SelectableCoinsUiState({
    required this.groups,
    required this.enabledSymbolGroups,
  });

  final List<CoinsGroup> groups;
  final Set<String> enabledSymbolGroups;

  bool isGroupEnabled(CoinsGroup group) => enabledSymbolGroups.contains(group.symbolGroup);
}
