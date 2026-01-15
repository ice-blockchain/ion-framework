// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tokenized_community_token_type.f.g.dart';

@JsonEnum(alwaysCreate: true)
enum TokenizedCommunityTokenType {
  @JsonValue('profile')
  tokenTypeProfile,

  @JsonValue('post')
  tokenTypePost,

  @JsonValue('article')
  tokenTypeArticle,

  @JsonValue('video')
  tokenTypeVideo,

  @JsonValue('xcom')
  tokenTypeXcom,

  @JsonValue('undefined')
  tokenTypeUndefined;

  factory TokenizedCommunityTokenType.fromJson(String json) =>
      _$TokenizedCommunityTokenTypeEnumMap.map((key, value) => MapEntry(value, key))[json] ??
      TokenizedCommunityTokenType.tokenTypeUndefined;

  String toJson() => _$TokenizedCommunityTokenTypeEnumMap[this]!;
}
