// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_token_analytics_response.f.freezed.dart';
part 'community_token_analytics_response.f.g.dart';

/// Response from GET .../v1/community-token-analytics/{analyticsType}?interval=24h|7d|30d
@freezed
class CommunityTokenAnalyticsResponse with _$CommunityTokenAnalyticsResponse {
  const factory CommunityTokenAnalyticsResponse({
    @Default(0) int launched,
    @Default(0) int migrated,
    @Default(0.0) double volume,
  }) = _CommunityTokenAnalyticsResponse;

  factory CommunityTokenAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$CommunityTokenAnalyticsResponseFromJson(json);
}
