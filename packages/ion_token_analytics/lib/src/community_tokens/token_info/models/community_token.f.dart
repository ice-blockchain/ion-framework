// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token_type.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';
import 'package:ion_token_analytics/src/core/map_utils.dart';

part 'community_token.f.freezed.dart';
part 'community_token.f.g.dart';

abstract class CommunityTokenBase {
  CommunityTokenType? get type;
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
    required CommunityTokenType type,
    required String title,
    required Addresses addresses,
    required Creator creator,
    required MarketData marketData,
    String? description,
    String? imageUrl,
    String? createdAt,
  }) = _CommunityToken;

  factory CommunityToken.fromJson(Map<String, dynamic> json) => _$CommunityTokenFromJson(json);
}

@Freezed(copyWith: false)
class CommunityTokenPatch with _$CommunityTokenPatch implements CommunityTokenBase {
  const factory CommunityTokenPatch({
    CommunityTokenType? type,
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

  String get externalAddress {
    final address = addresses.twitter ?? addresses.ionConnect;
    if (address == null) {
      throw Exception('External address is null');
    }
    return address;
  }

  CommunityTokenSource get source {
    if (addresses.twitter != null) {
      return CommunityTokenSource.twitter;
    }
    return CommunityTokenSource.ionConnect;
  }
}
