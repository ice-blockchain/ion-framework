// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_token_analytics_response.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunityTokenAnalyticsResponseImpl
_$$CommunityTokenAnalyticsResponseImplFromJson(Map<String, dynamic> json) =>
    _$CommunityTokenAnalyticsResponseImpl(
      launched: (json['launched'] as num?)?.toInt(),
      migrated: (json['migrated'] as num?)?.toInt(),
      volume: (json['volume'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$CommunityTokenAnalyticsResponseImplToJson(
  _$CommunityTokenAnalyticsResponseImpl instance,
) => <String, dynamic>{
  if (instance.launched case final value?) 'launched': value,
  if (instance.migrated case final value?) 'migrated': value,
  if (instance.volume case final value?) 'volume': value,
};
