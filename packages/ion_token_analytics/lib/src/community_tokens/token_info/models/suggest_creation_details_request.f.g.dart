// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggest_creation_details_request.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SuggestCreationDetailsRequestImpl
_$$SuggestCreationDetailsRequestImplFromJson(Map<String, dynamic> json) =>
    _$SuggestCreationDetailsRequestImpl(
      content: json['content'] as String,
      creator: CreatorInfo.fromJson(json['creator'] as Map<String, dynamic>),
      contentId: json['contentId'] as String,
      contentVideoFrames:
          (json['contentVideoFrames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SuggestCreationDetailsRequestImplToJson(
  _$SuggestCreationDetailsRequestImpl instance,
) => <String, dynamic>{
  'content': instance.content,
  'creator': instance.creator.toJson(),
  'contentId': instance.contentId,
  'contentVideoFrames': instance.contentVideoFrames,
};

_$CreatorInfoImpl _$$CreatorInfoImplFromJson(Map<String, dynamic> json) =>
    _$CreatorInfoImpl(
      name: json['name'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
    );

Map<String, dynamic> _$$CreatorInfoImplToJson(_$CreatorInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'username': instance.username,
      if (instance.bio case final value?) 'bio': value,
      if (instance.website case final value?) 'website': value,
    };
