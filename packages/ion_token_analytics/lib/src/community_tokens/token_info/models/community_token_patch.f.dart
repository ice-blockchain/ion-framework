// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/addresses_patch.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/community_token.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/creator.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/market_data_patch.f.dart';
import 'package:ion_token_analytics/src/community_tokens/token_info/models/patch.dart';

part 'community_token_patch.f.freezed.dart';
part 'community_token_patch.f.g.dart';

@freezed
class CommunityTokenPatch with _$CommunityTokenPatch, Patch<CommunityToken> {
  const factory CommunityTokenPatch({
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    AddressesPatch? addresses,
    Creator? creator, // Optional: present in full tokens, null in partial updates
    MarketDataPatch? marketData,
    String? createdAt,
  }) = _CommunityTokenPatch;

  factory CommunityTokenPatch.fromJson(Map<String, dynamic> json) =>
      _$CommunityTokenPatchFromJson(json);

  const CommunityTokenPatch._();

  @override
  CommunityToken merge(CommunityToken original) {
    return original.copyWith(
      type: type ?? original.type,
      title: title ?? original.title,
      description: description ?? original.description,
      imageUrl: imageUrl ?? original.imageUrl,
      addresses: addresses?.merge(original.addresses) ?? original.addresses,
      // Creator is immutable, so we don't merge it even if present in patch
      marketData: marketData?.merge(original.marketData) ?? original.marketData,
      createdAt: createdAt ?? original.createdAt,
    );
  }

  @override
  CommunityToken? toEntityOrNull() {
    if (creator == null) return null; // Can't create token without creator

    try {
      // Convert patch to JSON, then parse as full token
      final json = toJson();
      return CommunityToken.fromJson(json);
    } catch (_) {
      // If conversion fails, patch doesn't have all required fields
      return null;
    }
  }
}
