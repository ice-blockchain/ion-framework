// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_request_body.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NativeTransferRequestBodyImpl _$$NativeTransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$NativeTransferRequestBodyImpl(
      kind: json['kind'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$$NativeTransferRequestBodyImplToJson(
        _$NativeTransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'to': instance.to,
      'amount': instance.amount,
      'memo': instance.memo,
    };

_$Erc721TransferRequestBodyImpl _$$Erc721TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Erc721TransferRequestBodyImpl(
      kind: json['kind'] as String,
      contract: json['contract'] as String,
      to: json['to'] as String,
      tokenId: json['tokenId'] as String,
    );

Map<String, dynamic> _$$Erc721TransferRequestBodyImplToJson(
        _$Erc721TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'contract': instance.contract,
      'to': instance.to,
      'tokenId': instance.tokenId,
    };

_$AsaTransferRequestBodyImpl _$$AsaTransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$AsaTransferRequestBodyImpl(
      kind: json['kind'] as String,
      assetId: json['assetId'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$AsaTransferRequestBodyImplToJson(
        _$AsaTransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'assetId': instance.assetId,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Erc20TransferRequestBodyImpl _$$Erc20TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Erc20TransferRequestBodyImpl(
      kind: json['kind'] as String,
      contract: json['contract'] as String,
      amount: json['amount'] as String,
      to: json['to'] as String,
    );

Map<String, dynamic> _$$Erc20TransferRequestBodyImplToJson(
        _$Erc20TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'contract': instance.contract,
      'amount': instance.amount,
      'to': instance.to,
    };

_$SplTransferRequestBodyImpl _$$SplTransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$SplTransferRequestBodyImpl(
      kind: json['kind'] as String,
      mint: json['mint'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$SplTransferRequestBodyImplToJson(
        _$SplTransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'mint': instance.mint,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Spl2022TransferRequestBodyImpl _$$Spl2022TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Spl2022TransferRequestBodyImpl(
      kind: json['kind'] as String,
      mint: json['mint'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$Spl2022TransferRequestBodyImplToJson(
        _$Spl2022TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'mint': instance.mint,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Sep41TransferRequestBodyImpl _$$Sep41TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Sep41TransferRequestBodyImpl(
      kind: json['kind'] as String,
      issuer: json['issuer'] as String,
      assetCode: json['assetCode'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$$Sep41TransferRequestBodyImplToJson(
        _$Sep41TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'issuer': instance.issuer,
      'assetCode': instance.assetCode,
      'to': instance.to,
      'amount': instance.amount,
      'memo': instance.memo,
    };

_$Tep74TransferRequestBodyImpl _$$Tep74TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Tep74TransferRequestBodyImpl(
      kind: json['kind'] as String,
      master: json['master'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$Tep74TransferRequestBodyImplToJson(
        _$Tep74TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'master': instance.master,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Trc10TransferRequestBodyImpl _$$Trc10TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Trc10TransferRequestBodyImpl(
      kind: json['kind'] as String,
      tokenId: json['tokenId'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$Trc10TransferRequestBodyImplToJson(
        _$Trc10TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'tokenId': instance.tokenId,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Trc20TransferRequestBodyImpl _$$Trc20TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Trc20TransferRequestBodyImpl(
      kind: json['kind'] as String,
      contract: json['contract'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
    );

Map<String, dynamic> _$$Trc20TransferRequestBodyImplToJson(
        _$Trc20TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'contract': instance.contract,
      'to': instance.to,
      'amount': instance.amount,
    };

_$Trc721TransferRequestBodyImpl _$$Trc721TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Trc721TransferRequestBodyImpl(
      kind: json['kind'] as String,
      contract: json['contract'] as String,
      to: json['to'] as String,
      tokenId: json['tokenId'] as String,
    );

Map<String, dynamic> _$$Trc721TransferRequestBodyImplToJson(
        _$Trc721TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'contract': instance.contract,
      'to': instance.to,
      'tokenId': instance.tokenId,
    };

_$Aip21TransferRequestBodyImpl _$$Aip21TransferRequestBodyImplFromJson(
        Map<String, dynamic> json) =>
    _$Aip21TransferRequestBodyImpl(
      kind: json['kind'] as String,
      to: json['to'] as String,
      amount: json['amount'] as String,
      metadata: json['metadata'] as String,
    );

Map<String, dynamic> _$$Aip21TransferRequestBodyImplToJson(
        _$Aip21TransferRequestBodyImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'to': instance.to,
      'amount': instance.amount,
      'metadata': instance.metadata,
    };
