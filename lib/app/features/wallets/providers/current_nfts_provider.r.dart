// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/repository/nfts_repository.r.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/utils/concurrency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_nfts_provider.r.g.dart';

@Riverpod(keepAlive: true)
class CurrentNftsNotifier extends _$CurrentNftsNotifier {
  bool _incrementalSync = false;

  @override
  Future<List<NftData>> build() async {
    final nftsRepository = ref.watch(nftsRepositoryProvider);
    final walletViewData = await ref.watch(currentWalletViewDataProvider.future);

    _incrementalSync
        ? await nftsRepository.insertWalletNfts(walletViewData.nfts, walletId: walletViewData.id)
        : await nftsRepository.replaceWalletNfts(walletViewData.nfts, walletId: walletViewData.id);

    return mapWithConcurrency<NftData, NftData>(
      walletViewData.nfts,
      mapper: (nft) => nftsRepository.getNftExtras(nft, walletId: walletViewData.id),
    );
  }

  void enableIncrementalSync() => _incrementalSync = true;

  void resetToFullSync() {
    _incrementalSync = false;
    ref.invalidateSelf(); // Triggers the build method
  }
}
