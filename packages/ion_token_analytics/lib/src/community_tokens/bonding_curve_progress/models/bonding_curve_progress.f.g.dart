// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonding_curve_progress.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BondingCurveProgressImpl _$$BondingCurveProgressImplFromJson(
  Map<String, dynamic> json,
) => _$BondingCurveProgressImpl(
  currentAmount: json['currentAmount'] as String,
  currentAmountUSD: (json['currentAmountUSD'] as num).toDouble(),
  goalAmount: json['goalAmount'] as String,
  goalAmountUSD: (json['goalAmountUSD'] as num).toDouble(),
  migrated: json['migrated'] as bool,
  raisedAmount: json['raisedAmount'] as String,
);

Map<String, dynamic> _$$BondingCurveProgressImplToJson(
  _$BondingCurveProgressImpl instance,
) => <String, dynamic>{
  'currentAmount': instance.currentAmount,
  'currentAmountUSD': instance.currentAmountUSD,
  'goalAmount': instance.goalAmount,
  'goalAmountUSD': instance.goalAmountUSD,
  'migrated': instance.migrated,
  'raisedAmount': instance.raisedAmount,
};

_$BondingCurveProgressPatchImpl _$$BondingCurveProgressPatchImplFromJson(
  Map<String, dynamic> json,
) => _$BondingCurveProgressPatchImpl(
  currentAmount: json['currentAmount'] as String?,
  currentAmountUSD: (json['currentAmountUSD'] as num?)?.toDouble(),
  goalAmount: json['goalAmount'] as String?,
  goalAmountUSD: (json['goalAmountUSD'] as num?)?.toDouble(),
  migrated: json['migrated'] as bool?,
  raisedAmount: json['raisedAmount'] as String?,
);

Map<String, dynamic> _$$BondingCurveProgressPatchImplToJson(
  _$BondingCurveProgressPatchImpl instance,
) => <String, dynamic>{
  if (instance.currentAmount case final value?) 'currentAmount': value,
  if (instance.currentAmountUSD case final value?) 'currentAmountUSD': value,
  if (instance.goalAmount case final value?) 'goalAmount': value,
  if (instance.goalAmountUSD case final value?) 'goalAmountUSD': value,
  if (instance.migrated case final value?) 'migrated': value,
  if (instance.raisedAmount case final value?) 'raisedAmount': value,
};
