// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/nfts_repository.r.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_details_provider.r.g.dart';

@riverpod
Future<NftData?> nftDetails(Ref ref, NftIdentifier identifier) {
  final nftsRepository = ref.watch(nftsRepositoryProvider);

  return nftsRepository.getNftByIdentifier(identifier);
}
