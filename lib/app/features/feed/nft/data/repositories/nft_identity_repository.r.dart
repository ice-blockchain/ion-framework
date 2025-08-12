// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/nft/model/nft_collection_data.f.dart';
import 'package:ion/app/features/feed/nft/providers/nft_identity_dio_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nft_identity_repository.r.g.dart';

const _collectionNameHttpHeader = 'X-NFT-Collection-Name';
const _collectionAddressHttpHeader = 'X-NFT-Collection-Address';
const _collectionCreatedByHttpHeader = 'X-NFT-Collection-Created-By';

@Riverpod(keepAlive: true)
NftIdentityRepository nftIdentityRepository(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final baseUrl = env.get<String>(EnvVariable.NFT_IDENTITY_BASE_URL);

  final dio = ref.watch(nftIdentityDioProvider);

  return NftIdentityRepository(baseUrl, dio);
}

class NftIdentityRepository {
  const NftIdentityRepository(
    this.baseUrl,
    this._dio,
  );

  final String baseUrl;
  final Dio _dio;

  String _nftAccountPath(String masterKey) => '${baseUrl}account/$masterKey';

  Future<NftCollectionData?> getNftCollectionData({
    required String masterKey,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _nftAccountPath(masterKey),
      cancelToken: cancelToken,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final collectionName = response.headers.value(_collectionNameHttpHeader);
    final collectionAddress = response.headers.value(_collectionAddressHttpHeader);
    final createdBy = response.headers.value(_collectionCreatedByHttpHeader);

    if (collectionName != null && collectionAddress != null && createdBy != null) {
      return NftCollectionData(
        name: collectionName,
        collectionAddress: collectionAddress,
        creatorAddress: createdBy,
      );
    }

    return null;
  }
}
