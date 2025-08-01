// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nft_collection_response.f.freezed.dart';
part 'nft_collection_response.f.g.dart';

@freezed
class NftCollectionResponse with _$NftCollectionResponse {
  const factory NftCollectionResponse({
    @JsonKey(name: 'nft_collections') required List<NftCollection> nftCollections,
    @JsonKey(name: 'address_book') required Map<String, AddressBookEntry> addressBook,
    required Map<String, NftCollectionMetadata> metadata,
  }) = _NftCollectionResponse;

  factory NftCollectionResponse.fromJson(Map<String, dynamic> json) =>
      _$NftCollectionResponseFromJson(json);
}

@freezed
class NftCollection with _$NftCollection {
  const factory NftCollection({
    required String address,
    @JsonKey(name: 'owner_address') required String ownerAddress,
    @JsonKey(name: 'last_transaction_lt') required String lastTransactionLt,
    @JsonKey(name: 'next_item_index') required String nextItemIndex,
    @JsonKey(name: 'collection_content') required CollectionContent collectionContent,
    @JsonKey(name: 'data_hash') required String dataHash,
    @JsonKey(name: 'code_hash') required String codeHash,
  }) = _NftCollection;

  factory NftCollection.fromJson(Map<String, dynamic> json) => _$NftCollectionFromJson(json);
}

@freezed
class CollectionContent with _$CollectionContent {
  const factory CollectionContent({
    required String uri,
  }) = _CollectionContent;

  factory CollectionContent.fromJson(Map<String, dynamic> json) =>
      _$CollectionContentFromJson(json);
}

@freezed
class AddressBookEntry with _$AddressBookEntry {
  const factory AddressBookEntry({
    @JsonKey(name: 'user_friendly') required String userFriendly,
    String? domain,
  }) = _AddressBookEntry;

  factory AddressBookEntry.fromJson(Map<String, dynamic> json) => _$AddressBookEntryFromJson(json);
}

@freezed
class NftCollectionMetadata with _$NftCollectionMetadata {
  const factory NftCollectionMetadata({
    @JsonKey(name: 'is_indexed') required bool isIndexed,
    @JsonKey(name: 'token_info') required List<TokenInfo> tokenInfo,
  }) = _NftCollectionMetadata;

  factory NftCollectionMetadata.fromJson(Map<String, dynamic> json) =>
      _$NftCollectionMetadataFromJson(json);
}

@freezed
class TokenInfo with _$TokenInfo {
  const factory TokenInfo({
    required String type,
    String? name,
  }) = _TokenInfo;

  factory TokenInfo.fromJson(Map<String, dynamic> json) => _$TokenInfoFromJson(json);
}

@freezed
class TargetNftCollectionData with _$TargetNftCollectionData {
  const factory TargetNftCollectionData({
    required String name,
    required String collectionAddress,
    required String creatorAddress,
    required NftCollection collection,
  }) = _TargetNftCollectionData;

  factory TargetNftCollectionData.fromJson(Map<String, dynamic> json) =>
      _$TargetNftCollectionDataFromJson(json);
}
