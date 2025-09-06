// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';

part 'nft_data.f.freezed.dart';

@freezed
class NftData with _$NftData {
  const factory NftData({
    required String kind,
    required String contract,
    required String symbol,
    required String tokenId,
    required String tokenUri,
    required String description,
    required String name,
    required String collectionImageUri,
    required NetworkData network,
  }) = _NftData;
  const NftData._();

  NftIdentifier get identifier => NftIdentifier(contract: contract, tokenId: tokenId);

  String get imageUrl => collectionImageUri.isNotEmpty ? collectionImageUri : tokenUri;
}
