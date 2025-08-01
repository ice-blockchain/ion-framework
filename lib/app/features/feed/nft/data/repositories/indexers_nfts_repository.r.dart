// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_response.f.dart';
import 'package:ion/app/features/feed/nft/model/nft_collections_query.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'indexers_nfts_repository.r.g.dart';

@riverpod
IndexersNftsRepository indexersNftsRepository(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final baseUrl = env.get<String>(EnvVariable.INDEXER_BASE_URL);

  return IndexersNftsRepository(
    baseUrl,
    ref.watch(dioProvider),
  );
}

class IndexersNftsRepository {
  const IndexersNftsRepository(
    this.baseUrl,
    this._dio,
  );

  final String baseUrl;
  final Dio _dio;

  String get nftCollectionsPath => '${baseUrl}v3/nft/collections';

  /// Fetches NFT collections from the indexer API
  Future<NftCollectionResponse> getNftCollections({
    required NftCollectionsQuery query,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      nftCollectionsPath,
      queryParameters: query.toJson(),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to fetch NFT collections:  ${response.statusCode}');
    }

    return NftCollectionResponse.fromJson(response.data!);
  }
}
