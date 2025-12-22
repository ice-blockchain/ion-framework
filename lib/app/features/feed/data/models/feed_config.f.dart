// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/config/data/models/app_config_with_version.dart';

part 'feed_config.f.freezed.dart';
part 'feed_config.f.g.dart';

@freezed
class FeedConfig with _$FeedConfig implements AppConfigWithVersion {
  const factory FeedConfig({
    @JsonKey(name: '_version') required int version,
    required double interestedThreshold,
    required double notInterestedCategoryChance,
    required int concurrentRequests,
    required int concurrentMediaDownloadsLimit,
    required int concurrentBigFileUploadChunks,
    required double forYouOverflowMultiplier,
    required double forYouSeenSkipsMultiplier,
    @DurationMillisecondsConverter() required Duration followingReqMaxAge,
    @DurationMillisecondsConverter() required Duration followingCacheMaxAge,
    @DurationMillisecondsConverter() required Duration topMaxAge,
    @DurationMillisecondsConverter() required Duration trendingMaxAge,
    @DurationMillisecondsConverter() required Duration exploreMaxAge,
    @DurationMillisecondsConverter() required Duration repostThrottleDelay,
    required bool excludeUnclassifiedFromExplore,
    required double forYouMaxRetriesMultiplier,
    required double followingMaxRetriesMultiplier,
    required double nsfwBlockThreshold,
    required double langDetectScoreThreshold,
    required String cdnBaseUrl,
    @Default(true) bool allowNewRegistrations,
    @Default(false) bool enableEarlyAccessRegistrations,
    @Default(true) bool forceSecurityEnabled,
    @DurationMillisecondsConverter() @Default(Duration(days: 5)) Duration tokenizedCommunitiesMaxAge,
  }) = _FeedConfig;

  const FeedConfig._();

  factory FeedConfig.fromJson(Map<String, dynamic> json) => _$FeedConfigFromJson(json);
}

class DurationMillisecondsConverter implements JsonConverter<Duration, int> {
  const DurationMillisecondsConverter();

  @override
  Duration fromJson(int milliseconds) => Duration(milliseconds: milliseconds);

  @override
  int toJson(Duration duration) => duration.inMilliseconds;
}
