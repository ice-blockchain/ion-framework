// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/domain/coins/search_coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/manage_coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/update_wallet_view_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manage_coins_provider.r.g.dart';
part 'required_coin_groups_list.dart';

@riverpod
class ManageCoinsNotifier extends _$ManageCoinsNotifier {
  final _coinsFromWallet = <String, ManageCoinsGroup>{};
  var _saveEnabled = true;

  @override
  Future<Map<String, ManageCoinsGroup>> build() async {
    _coinsFromWallet.clear();
    final loadedGroupsToSymbolGroup = <String, ManageCoinsGroup>{};
    final toExclude = <String>{};

    final walletView = await ref.watch(currentWalletViewDataProvider.future);

    for (final coinGroup in walletView.coinGroups) {
      toExclude.addAll(coinGroup.coins.map((e) => e.coin.id));
      _coinsFromWallet[coinGroup.symbolGroup] = ManageCoinsGroup(
        coinsGroup: coinGroup,
        isSelected: true,
      );
    }
    final coinsService = await ref.watch(coinsServiceProvider.future);
    final loadedGroups = await coinsService.getCoinGroups(
      symbolGroups: _coinGroups,
      excludeCoinIds: toExclude,
    );
    loadedGroupsToSymbolGroup.addAll({
      for (final group in loadedGroups)
        group.symbolGroup: ManageCoinsGroup(
          coinsGroup: group,
          isSelected: state.value?[group.symbolGroup]?.isSelected ??
              false || _coinsFromWallet.keys.contains(group.symbolGroup),
        ),
    });

    final tcGroups = await coinsService.getCoinGroups(
      isTokenizedCommunity: true,
      excludeCoinIds: toExclude,
    );
    final tcGroupsToSymbolGroup = <String, ManageCoinsGroup>{};
    for (final group in tcGroups) {
      if (!_coinsFromWallet.containsKey(group.symbolGroup) &&
          !loadedGroupsToSymbolGroup.containsKey(group.symbolGroup)) {
        tcGroupsToSymbolGroup[group.symbolGroup] = ManageCoinsGroup(
          coinsGroup: group,
          isSelected: state.value?[group.symbolGroup]?.isSelected ?? false,
        );
      }
    }

    final groups = {
      ..._coinsFromWallet,
      ...tcGroupsToSymbolGroup,
      ...loadedGroupsToSymbolGroup,
    };

    return groups;
  }

  Future<void> switchCoinsGroup(CoinsGroup coinsGroup) async {
    final currentMap = state.value ?? <String, ManageCoinsGroup>{};
    final currentGroup = currentMap[coinsGroup.symbolGroup];
    final isNewlyAdded =
        !currentMap.containsKey(coinsGroup.symbolGroup) || !(currentGroup?.isSelected ?? true);
    final isBeingDeleted =
        _coinsFromWallet.containsKey(coinsGroup.symbolGroup) || !(currentGroup?.isSelected ?? true);
    final isUpdating = (isNewlyAdded || isBeingDeleted) && !(currentGroup?.isUpdating ?? false);

    currentMap[coinsGroup.symbolGroup] = ManageCoinsGroup(
      coinsGroup: coinsGroup,
      isSelected: !(currentGroup?.isSelected ?? false),
      isUpdating: isUpdating,
    );
    state = AsyncData<Map<String, ManageCoinsGroup>>(currentMap);
  }

  void disableSave() {
    _saveEnabled = false;
  }

  void enableSave() {
    _saveEnabled = true;
  }

  Future<void> save() async {
    if (!_saveEnabled) return;

    final currentWalletView = await ref.read(currentWalletViewDataProvider.future);
    final updatedCoins = state.value?.values
            .where((manageGroup) => manageGroup.isSelected)
            .expand((manageGroup) => manageGroup.coinsGroup.coins)
            .map((e) => e.coin)
            .toList() ??
        [];

    final walletCoins =
        currentWalletView.coinGroups.expand((e) => e.coins).map((e) => e.coin).toList();

    final updateRequired = !(const ListEquality<CoinData>().equals(updatedCoins, walletCoins));

    if (updateRequired) {
      unawaited(
        ref.read(updateWalletViewNotifierProvider.notifier).updateWalletView(
              walletView: currentWalletView,
              updatedCoinsList: updatedCoins,
            ),
      );
    }
  }
}

@riverpod
class SearchCoinsNotifier extends _$SearchCoinsNotifier {
  @override
  Future<Set<CoinsGroup>> build() async => {};

  Future<void> search({required String query}) async {
    if (query.isEmpty) {
      state = ref.read(manageCoinsNotifierProvider).map(
            data: (data) => AsyncData(
              data.value.values.map((manageCoin) => manageCoin.coinsGroup).toSet(),
            ),
            error: (error) => AsyncError(error.error, error.stackTrace),
            loading: (loading) => const AsyncLoading(),
          );
      return;
    }

    await ref.debounce();

    final searchService = ref.read(searchCoinsServiceProvider);
    final searchResult = await searchService.search(query).then((coinGroups) {
      return {for (final group in coinGroups) group.symbolGroup: group};
    });
    state = ref.read(manageCoinsNotifierProvider).maybeWhen(
          data: (coinsInWalletView) {
            final walletCoinGroups =
                coinsInWalletView.values.map((manageGroup) => manageGroup.coinsGroup).toList();

            // Coins from wallet should be first in the search results list
            final result = <CoinsGroup>{};
            for (final coinsGroup in walletCoinGroups) {
              final coinsGroupFromWalletView = searchResult[coinsGroup.symbolGroup];
              if (coinsGroupFromWalletView != null) {
                result.add(coinsGroupFromWalletView);
              }
            }
            result.addAll(searchResult.values);

            return AsyncData(result);
          },
          orElse: () => const AsyncLoading(),
        );
  }
}
