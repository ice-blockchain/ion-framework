// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PositionImpl _$$PositionImplFromJson(Map<String, dynamic> json) =>
    _$PositionImpl(
      rank: (json['rank'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      amountUSD: (json['amountUSD'] as num).toDouble(),
      pnl: (json['pnl'] as num).toDouble(),
      pnlPercentage: (json['pnlPercentage'] as num).toDouble(),
    );

Map<String, dynamic> _$$PositionImplToJson(_$PositionImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'amount': instance.amount,
      'amountUSD': instance.amountUSD,
      'pnl': instance.pnl,
      'pnlPercentage': instance.pnlPercentage,
    };
