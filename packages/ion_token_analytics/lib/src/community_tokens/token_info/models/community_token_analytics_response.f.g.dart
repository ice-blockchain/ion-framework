// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_token_analytics_response.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunityTokenAnalyticsResponseImpl
_$$CommunityTokenAnalyticsResponseImplFromJson(Map<String, dynamic> json) =>
    _$CommunityTokenAnalyticsResponseImpl(
      launched: (json['launched'] as num?)?.toInt() ?? 0,
      migrated: (json['migrated'] as num?)?.toInt() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$CommunityTokenAnalyticsResponseImplToJson(
  _$CommunityTokenAnalyticsResponseImpl instance,
) => <String, dynamic>{
  'launched': instance.launched,
  'migrated': instance.migrated,
  'volume': instance.volume,
};
