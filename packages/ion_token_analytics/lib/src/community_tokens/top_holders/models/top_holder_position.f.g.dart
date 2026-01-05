// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'top_holder_position.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TopHolderPositionImpl _$$TopHolderPositionImplFromJson(
  Map<String, dynamic> json,
) => _$TopHolderPositionImpl(
  rank: (json['rank'] as num).toInt(),
  amount: json['amount'] as String,
  amountUSD: (json['amountUSD'] as num).toDouble(),
  supplyShare: (json['supplyShare'] as num).toDouble(),
  holder: json['holder'] == null
      ? null
      : Creator.fromJson(json['holder'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$TopHolderPositionImplToJson(
  _$TopHolderPositionImpl instance,
) => <String, dynamic>{
  'rank': instance.rank,
  'amount': instance.amount,
  'amountUSD': instance.amountUSD,
  'supplyShare': instance.supplyShare,
  if (instance.holder?.toJson() case final value?) 'holder': value,
};

_$TopHolderPositionPatchImpl _$$TopHolderPositionPatchImplFromJson(
  Map<String, dynamic> json,
) => _$TopHolderPositionPatchImpl(
  holder: json['holder'] == null
      ? null
      : Creator.fromJson(json['holder'] as Map<String, dynamic>),
  rank: (json['rank'] as num?)?.toInt(),
  amount: json['amount'] as String?,
  amountUSD: (json['amountUSD'] as num?)?.toDouble(),
  supplyShare: (json['supplyShare'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$TopHolderPositionPatchImplToJson(
  _$TopHolderPositionPatchImpl instance,
) => <String, dynamic>{
  if (instance.holder?.toJson() case final value?) 'holder': value,
  if (instance.rank case final value?) 'rank': value,
  if (instance.amount case final value?) 'amount': value,
  if (instance.amountUSD case final value?) 'amountUSD': value,
  if (instance.supplyShare case final value?) 'supplyShare': value,
};
