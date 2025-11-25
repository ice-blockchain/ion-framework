// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/map_utils.dart';

part 'community_token.f.freezed.dart';
part 'community_token.f.g.dart';

abstract class CommunityTokenBase {
  String? get type;
  String? get title;
  String? get description;
  String? get imageUrl;
  AddressesBase? get addresses;
  CreatorBase? get creator;
  MarketDataBase? get marketData;
  String? get createdAt;
}

@freezed
class CommunityToken with _$CommunityToken implements CommunityTokenBase {
  const factory CommunityToken({
    required String type,
    required String title,
    required String description,
    required String imageUrl,
    required Addresses addresses,
    required Creator creator,
    required MarketData marketData,
    String? createdAt,
  }) = _CommunityToken;

  factory CommunityToken.fromJson(Map<String, dynamic> json) => _$CommunityTokenFromJson(json);
}

@Freezed(copyWith: false)
class CommunityTokenPatch with _$CommunityTokenPatch implements CommunityTokenBase {
  const factory CommunityTokenPatch({
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    AddressesPatch? addresses,
    CreatorPatch? creator,
    MarketDataPatch? marketData,
    String? createdAt,
  }) = _CommunityTokenPatch;

  factory CommunityTokenPatch.fromJson(Map<String, dynamic> json) =>
      _$CommunityTokenPatchFromJson(json);
}

extension CommunityTokenPatchExtension on CommunityTokenPatch {
  bool isEmpty() {
    return type == null &&
        title == null &&
        description == null &&
        imageUrl == null &&
        addresses == null &&
        creator == null &&
        marketData == null;
  }
}

extension CommunityTokenExtension on CommunityToken {
  CommunityToken merge(CommunityTokenPatch patch) {
    final orgJson = toJson();
    final patchJson = patch.toJson();

    final mergedJson = deepMerge(orgJson, patchJson);

    return CommunityToken.fromJson(mergedJson);
  }
}
