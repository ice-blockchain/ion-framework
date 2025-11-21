// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_holder_position.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopHolderPositionImpl _$$TopHolderPositionImplFromJson(
  Map<String, dynamic> json,
) => _$TopHolderPositionImpl(
  holder: Creator.fromJson(json['holder'] as Map<String, dynamic>),
  type: json['type'] as String,
  rank: (json['rank'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  amountUSD: (json['amountUSD'] as num).toDouble(),
  supplyShare: (json['supplyShare'] as num).toDouble(),
  addresses: Addresses.fromJson(json['addresses'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$TopHolderPositionImplToJson(
  _$TopHolderPositionImpl instance,
) => <String, dynamic>{
  'holder': instance.holder.toJson(),
  'type': instance.type,
  'rank': instance.rank,
  'amount': instance.amount,
  'amountUSD': instance.amountUSD,
  'supplyShare': instance.supplyShare,
  'addresses': instance.addresses.toJson(),
};
