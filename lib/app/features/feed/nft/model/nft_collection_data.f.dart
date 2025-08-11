// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nft_collection_data.f.freezed.dart';

@freezed
class NftCollectionData with _$NftCollectionData {
  const factory NftCollectionData({
    required String name,
    required String collectionAddress,
    required String creatorAddress,
  }) = _NftCollectionData;
}
