// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/models.dart';

part 'community_token.f.freezed.dart';
part 'community_token.f.g.dart';

@freezed
class CommunityToken with _$CommunityToken {
  const factory CommunityToken({
    required String type,
    required String title,
    required String description,
    required String imageUrl,
    required Addresses addresses,
    required Creator creator,
    required MarketData marketData,
  }) = _CommunityToken;

  factory CommunityToken.fromJson(Map<String, dynamic> json) => _$CommunityTokenFromJson(json);
}

@Freezed(copyWith: false)
class CommunityTokenPatch with _$CommunityTokenPatch {
  const factory CommunityTokenPatch({
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    AddressesPatch? addresses,
    CreatorPatch? creator,
    MarketDataPatch? marketData,
  }) = _CommunityTokenPatch;

  factory CommunityTokenPatch.fromJson(Map<String, dynamic> json) =>
      _$CommunityTokenPatchFromJson(json);
}
