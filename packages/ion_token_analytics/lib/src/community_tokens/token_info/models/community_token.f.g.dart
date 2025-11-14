// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_token.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunityTokenImpl _$$CommunityTokenImplFromJson(Map<String, dynamic> json) =>
    _$CommunityTokenImpl(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      addresses: Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      marketData: MarketData.fromJson(
        json['marketData'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$$CommunityTokenImplToJson(
  _$CommunityTokenImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'addresses': instance.addresses.toJson(),
  'creator': instance.creator.toJson(),
  'marketData': instance.marketData.toJson(),
};
