// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/nft/data/repositories/nft_identity_repository.r.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_collection_sync_service.r.g.dart';

/// Service responsible for business logic related to NFT collection sync.
class NftCollectionSyncService {
  NftCollectionSyncService({
    required this.repository,
  });

  final NftIdentityRepository repository;

  Future<NftCollectionData?> getNftCollectionData({
    required String userMasterKey,
    CancelToken? cancelToken,
  }) async {
    return repository.getNftCollectionData(
      masterKey: userMasterKey,
      cancelToken: cancelToken,
    );
  }
}

@Riverpod(keepAlive: true)
NftCollectionSyncService nftCollectionSyncService(Ref ref) {
  final repository = ref.watch(nftIdentityRepositoryProvider);
  return NftCollectionSyncService(repository: repository);
}
