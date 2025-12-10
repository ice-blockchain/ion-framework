// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/domain/coins/search_coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_coins_notifier_provider.r.g.dart';

@riverpod
class SearchCoinsNotifier extends _$SearchCoinsNotifier {
  @override
  Future<List<CoinsGroup>> build() async {
    final walletView = ref.read(currentWalletViewDataProvider);
    return walletView.maybeWhen(
      data: (data) => data.coinGroups,
      orElse: () => <CoinsGroup>[],
    );
  }

  Future<void> search({required String query}) async {
    if (query.isEmpty) {
      final walletView = ref.read(currentWalletViewDataProvider);
      state = walletView.map(
        data: (data) => AsyncData(
          data.value.coinGroups,
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
    state = ref.read(currentWalletViewDataProvider).maybeWhen(
          data: (data) {
            // Coins from wallet should be first in the search results list
            final result = <CoinsGroup>{};
            for (final coinsGroup in data.coinGroups) {
              final coinsGroupFromWalletView = searchResult[coinsGroup.symbolGroup];
              if (coinsGroupFromWalletView != null) {
                result.add(coinsGroupFromWalletView);
              }
            }
            result.addAll(searchResult.values);

            return AsyncData(result.toList());
          },
          orElse: () => const AsyncLoading(),
        );
  }
}
