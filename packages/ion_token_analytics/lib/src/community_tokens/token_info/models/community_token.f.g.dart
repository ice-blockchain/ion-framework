// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_token.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommunityTokenImpl _$$CommunityTokenImplFromJson(Map<String, dynamic> json) =>
    _$CommunityTokenImpl(
      type: $enumDecode(_$CommunityTokenTypeEnumMap, json['type']),
      title: json['title'] as String,
      addresses: Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      marketData: MarketData.fromJson(
        json['marketData'] as Map<String, dynamic>,
      ),
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$$CommunityTokenImplToJson(
  _$CommunityTokenImpl instance,
) => <String, dynamic>{
  'type': _$CommunityTokenTypeEnumMap[instance.type]!,
  'title': instance.title,
  'addresses': instance.addresses.toJson(),
  'creator': instance.creator.toJson(),
  'marketData': instance.marketData.toJson(),
  if (instance.description case final value?) 'description': value,
  if (instance.imageUrl case final value?) 'imageUrl': value,
  if (instance.createdAt case final value?) 'createdAt': value,
};

const _$CommunityTokenTypeEnumMap = {
  CommunityTokenType.profile: 'profile',
  CommunityTokenType.post: 'post',
  CommunityTokenType.video: 'video',
  CommunityTokenType.article: 'article',
};

_$CommunityTokenPatchImpl _$$CommunityTokenPatchImplFromJson(
  Map<String, dynamic> json,
) => _$CommunityTokenPatchImpl(
  type: $enumDecodeNullable(_$CommunityTokenTypeEnumMap, json['type']),
  title: json['title'] as String?,
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String?,
  addresses: json['addresses'] == null
      ? null
      : AddressesPatch.fromJson(json['addresses'] as Map<String, dynamic>),
  creator: json['creator'] == null
      ? null
      : CreatorPatch.fromJson(json['creator'] as Map<String, dynamic>),
  marketData: json['marketData'] == null
      ? null
      : MarketDataPatch.fromJson(json['marketData'] as Map<String, dynamic>),
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$$CommunityTokenPatchImplToJson(
  _$CommunityTokenPatchImpl instance,
) => <String, dynamic>{
  if (_$CommunityTokenTypeEnumMap[instance.type] case final value?)
    'type': value,
  if (instance.title case final value?) 'title': value,
  if (instance.description case final value?) 'description': value,
  if (instance.imageUrl case final value?) 'imageUrl': value,
  if (instance.addresses?.toJson() case final value?) 'addresses': value,
  if (instance.creator?.toJson() case final value?) 'creator': value,
  if (instance.marketData?.toJson() case final value?) 'marketData': value,
  if (instance.createdAt case final value?) 'createdAt': value,
};
