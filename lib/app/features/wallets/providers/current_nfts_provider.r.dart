// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/nfts_repository.r.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_nfts_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<List<NftData>> currentNfts(Ref ref) async {
  final nftsRepository = ref.watch(nftsRepositoryProvider);

  final walletViewData = await ref.watch(currentWalletViewDataProvider.future);

  // Replace wallet NFTs to reflect current server state
  await nftsRepository.replaceWalletNfts(walletViewData.nfts, walletId: walletViewData.id);

  // Enrich with metadata in parallel
  final futures = walletViewData.nfts
      .map((nft) => nftsRepository.getNftExtras(nft, walletId: walletViewData.id))
      .toList();

  return Future.wait(futures);
}
