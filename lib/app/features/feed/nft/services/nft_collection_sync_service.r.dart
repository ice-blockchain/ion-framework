// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/nft/data/repositories/indexers_nfts_repository.r.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_response.f.dart';
import 'package:ion/app/features/feed/nft/model/nft_collections_query.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_collection_sync_service.r.g.dart';

// TODO: clarify the name when available
const ionContentNftCollectionName = 'ION_CONTENT_NFT';

const nftCollectionsTokenType = 'nft_collections';

/// Service responsible for business logic related to NFT collection sync.
class NftCollectionSyncService {
  NftCollectionSyncService({
    required this.repository,
  });

  final IndexersNftsRepository repository;

  /// Fetches NFT collections for the given user and searches for the target collection,
  /// handling pagination internally.
  Future<TargetNftCollectionData?> fetchAndFindTargetCollection({
    required String userMasterKey,
    String targetCollectionName = ionContentNftCollectionName,
    CancelToken? cancelToken,
  }) async {
    var offset = 0;
    var hasMore = true;

    while (hasMore) {
      final response = await repository.getNftCollections(
        query: NftCollectionsQuery(
          ownerAddress: userMasterKey,
          offset: offset,
        ),
        cancelToken: cancelToken,
      );
      final foundCollection = _findTargetCollection(response, targetCollectionName);
      if (foundCollection != null) {
        return foundCollection;
      }

      if (response.nftCollections.length < defaultNftCollectionsLimit) {
        hasMore = false;
      } else {
        offset += defaultNftCollectionsLimit;
      }
    }
    return null;
  }

  /// Finds the target NFT collection in the response.
  TargetNftCollectionData? _findTargetCollection(
    NftCollectionResponse response,
    String targetCollectionName,
  ) {
    for (final collection in response.nftCollections) {
      final metadata = response.metadata[collection.address];
      if (metadata == null) continue;

      for (final tokenInfo in metadata.tokenInfo) {
        if (tokenInfo.type == nftCollectionsTokenType &&
            (tokenInfo.name == targetCollectionName || tokenInfo.name == null)) {
          // Extract creator address (currently using collection address as placeholder)
          final creatorAddress = _extractCreatorAddress(response, collection.address);

          return TargetNftCollectionData(
            // TODO: clarify the name when available
            name: tokenInfo.name ?? targetCollectionName,
            collectionAddress: collection.address,
            creatorAddress: creatorAddress,
            collection: collection,
          );
        }
      }
    }
    return null;
  }

  /// Extracts creator address from the response.
  /// TODO: Clarify where the actual creator address is located in the response.
  String _extractCreatorAddress(NftCollectionResponse response, String collectionAddress) {
    // For now, return the collection address as a placeholder.
    return collectionAddress;
  }
}

@Riverpod(keepAlive: true)
NftCollectionSyncService nftCollectionSyncService(Ref ref) {
  final repository = ref.watch(indexersNftsRepositoryProvider);
  return NftCollectionSyncService(repository: repository);
}
