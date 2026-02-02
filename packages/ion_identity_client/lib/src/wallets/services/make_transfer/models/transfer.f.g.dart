// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NativeTokenTransferImpl _$$NativeTokenTransferImplFromJson(
        Map<String, dynamic> json) =>
    _$NativeTokenTransferImpl(
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Native',
      priority:
          $enumDecodeNullable(_$TransferPriorityEnumMap, json['priority']),
      memo: json['memo'] as String?,
      createDestinationAccount: json['createDestinationAccount'] as bool?,
    );

Map<String, dynamic> _$$NativeTokenTransferImplToJson(
        _$NativeTokenTransferImpl instance) =>
    <String, dynamic>{
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.priority?.toJson() case final value?) 'priority': value,
      if (instance.memo case final value?) 'memo': value,
      if (instance.createDestinationAccount case final value?)
        'createDestinationAccount': value,
    };

const _$TransferPriorityEnumMap = {
  TransferPriority.slow: 'slow',
  TransferPriority.standard: 'standard',
  TransferPriority.fast: 'fast',
};

_$AsaTransferImpl _$$AsaTransferImplFromJson(Map<String, dynamic> json) =>
    _$AsaTransferImpl(
      assetId: json['assetId'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Asa',
    );

Map<String, dynamic> _$$AsaTransferImplToJson(_$AsaTransferImpl instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
    };

_$Erc20TransferImpl _$$Erc20TransferImplFromJson(Map<String, dynamic> json) =>
    _$Erc20TransferImpl(
      contract: json['contract'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Erc20',
      priority:
          $enumDecodeNullable(_$TransferPriorityEnumMap, json['priority']),
    );

Map<String, dynamic> _$$Erc20TransferImplToJson(_$Erc20TransferImpl instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.priority?.toJson() case final value?) 'priority': value,
    };

_$Erc721TransferImpl _$$Erc721TransferImplFromJson(Map<String, dynamic> json) =>
    _$Erc721TransferImpl(
      contract: json['contract'] as String,
      to: json['to'] as String,
      tokenId: json['tokenId'] as String,
      kind: json['kind'] as String? ?? 'Erc721',
      priority:
          $enumDecodeNullable(_$TransferPriorityEnumMap, json['priority']),
    );

Map<String, dynamic> _$$Erc721TransferImplToJson(
        _$Erc721TransferImpl instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'to': instance.to,
      'tokenId': instance.tokenId,
      'kind': instance.kind,
      if (instance.priority?.toJson() case final value?) 'priority': value,
    };

_$SplTransferImpl _$$SplTransferImplFromJson(Map<String, dynamic> json) =>
    _$SplTransferImpl(
      mint: json['mint'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Spl',
      createDestinationAccount: json['createDestinationAccount'] as bool?,
    );

Map<String, dynamic> _$$SplTransferImplToJson(_$SplTransferImpl instance) =>
    <String, dynamic>{
      'mint': instance.mint,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.createDestinationAccount case final value?)
        'createDestinationAccount': value,
    };

_$Spl2022TransferImpl _$$Spl2022TransferImplFromJson(
        Map<String, dynamic> json) =>
    _$Spl2022TransferImpl(
      mint: json['mint'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Spl2022',
      createDestinationAccount: json['createDestinationAccount'] as bool?,
    );

Map<String, dynamic> _$$Spl2022TransferImplToJson(
        _$Spl2022TransferImpl instance) =>
    <String, dynamic>{
      'mint': instance.mint,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.createDestinationAccount case final value?)
        'createDestinationAccount': value,
    };

_$Sep41TransferImpl _$$Sep41TransferImplFromJson(Map<String, dynamic> json) =>
    _$Sep41TransferImpl(
      issuer: json['issuer'] as String,
      assetCode: json['assetCode'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Sep41',
      memo: json['memo'] as String?,
      createDestinationAccount: json['createDestinationAccount'] as bool?,
    );

Map<String, dynamic> _$$Sep41TransferImplToJson(_$Sep41TransferImpl instance) =>
    <String, dynamic>{
      'issuer': instance.issuer,
      'assetCode': instance.assetCode,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.memo case final value?) 'memo': value,
      if (instance.createDestinationAccount case final value?)
        'createDestinationAccount': value,
    };

_$Tep74TransferImpl _$$Tep74TransferImplFromJson(Map<String, dynamic> json) =>
    _$Tep74TransferImpl(
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Tep74',
      master: json['master'] as String?,
    );

Map<String, dynamic> _$$Tep74TransferImplToJson(_$Tep74TransferImpl instance) =>
    <String, dynamic>{
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
      if (instance.master case final value?) 'master': value,
    };

_$Trc10TransferImpl _$$Trc10TransferImplFromJson(Map<String, dynamic> json) =>
    _$Trc10TransferImpl(
      tokenId: json['tokenId'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Trc10',
    );

Map<String, dynamic> _$$Trc10TransferImplToJson(_$Trc10TransferImpl instance) =>
    <String, dynamic>{
      'tokenId': instance.tokenId,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
    };

_$Trc20TransferImpl _$$Trc20TransferImplFromJson(Map<String, dynamic> json) =>
    _$Trc20TransferImpl(
      contract: json['contract'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Trc20',
    );

Map<String, dynamic> _$$Trc20TransferImplToJson(_$Trc20TransferImpl instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
    };

_$Trc721TransferImpl _$$Trc721TransferImplFromJson(Map<String, dynamic> json) =>
    _$Trc721TransferImpl(
      contract: json['contract'] as String,
      to: json['to'] as String,
      tokenId: json['tokenId'] as String,
      kind: json['kind'] as String? ?? 'Trc721',
    );

Map<String, dynamic> _$$Trc721TransferImplToJson(
        _$Trc721TransferImpl instance) =>
    <String, dynamic>{
      'contract': instance.contract,
      'to': instance.to,
      'tokenId': instance.tokenId,
      'kind': instance.kind,
    };

_$Aip21TransferImpl _$$Aip21TransferImplFromJson(Map<String, dynamic> json) =>
    _$Aip21TransferImpl(
      metadata: json['metadata'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      kind: json['kind'] as String? ?? 'Aip21',
    );

Map<String, dynamic> _$$Aip21TransferImplToJson(_$Aip21TransferImpl instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'to': instance.to,
      'amount': instance.amount,
      'kind': instance.kind,
    };

_$Eip1559ContractCallTransferImpl _$$Eip1559ContractCallTransferImplFromJson(
        Map<String, dynamic> json) =>
    _$Eip1559ContractCallTransferImpl(
      to: json['to'] as String,
      data: json['data'] as String,
      value: json['value'] as String,
      maxFeePerGas: json['maxFeePerGas'] as String,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String,
      kind: json['kind'] as String? ?? 'Eip1559',
    );

Map<String, dynamic> _$$Eip1559ContractCallTransferImplToJson(
        _$Eip1559ContractCallTransferImpl instance) =>
    <String, dynamic>{
      'to': instance.to,
      'data': instance.data,
      'value': instance.value,
      'maxFeePerGas': instance.maxFeePerGas,
      'maxPriorityFeePerGas': instance.maxPriorityFeePerGas,
      'kind': instance.kind,
    };
