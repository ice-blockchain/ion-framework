// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/wallets/providers/filtered_assets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_page_loader_provider.r.g.dart';

@riverpod
class WalletPageLoaderNotifier extends _$WalletPageLoaderNotifier {
  @override
  bool build() {
    final coinsLoading = ref.watch(
      filteredCoinsNotifierProvider.select((state) => !state.hasValue),
    );
    final friendsLoading = ref.watch(
      currentUserFollowListProvider.select((state) => !state.hasValue),
    );
    final walletLoading = ref.watch(
      currentWalletViewDataProvider.select((state) => !state.hasValue),
    );

    return coinsLoading || friendsLoading || walletLoading;
  }
}
