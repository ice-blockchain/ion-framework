// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PositionImpl _$$PositionImplFromJson(Map<String, dynamic> json) =>
    _$PositionImpl(
      rank: (json['rank'] as num).toInt(),
      amount: json['amount'] as String,
      amountUSD: (json['amountUSD'] as num?)?.toDouble() ?? 0,
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
      pnlPercentage: (json['pnlPercentage'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$PositionImplToJson(_$PositionImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'amount': instance.amount,
      'amountUSD': instance.amountUSD,
      'pnl': instance.pnl,
      'pnlPercentage': instance.pnlPercentage,
    };

_$PositionPatchImpl _$$PositionPatchImplFromJson(Map<String, dynamic> json) =>
    _$PositionPatchImpl(
      rank: (json['rank'] as num?)?.toInt(),
      amount: json['amount'] as String?,
      amountUSD: (json['amountUSD'] as num?)?.toDouble(),
      pnl: (json['pnl'] as num?)?.toDouble(),
      pnlPercentage: (json['pnlPercentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$PositionPatchImplToJson(_$PositionPatchImpl instance) =>
    <String, dynamic>{
      if (instance.rank case final value?) 'rank': value,
      if (instance.amount case final value?) 'amount': value,
      if (instance.amountUSD case final value?) 'amountUSD': value,
      if (instance.pnl case final value?) 'pnl': value,
      if (instance.pnlPercentage case final value?) 'pnlPercentage': value,
    };
