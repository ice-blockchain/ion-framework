// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_holder.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopHolderImpl _$$TopHolderImplFromJson(Map<String, dynamic> json) =>
    _$TopHolderImpl(
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      position: TopHolderPosition.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$$TopHolderImplToJson(_$TopHolderImpl instance) =>
    <String, dynamic>{
      'creator': instance.creator.toJson(),
      'position': instance.position.toJson(),
    };
