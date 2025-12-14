// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evm_broadcast_request.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvmTransactionHexBroadcastRequestImpl
    _$$EvmTransactionHexBroadcastRequestImplFromJson(
            Map<String, dynamic> json) =>
        _$EvmTransactionHexBroadcastRequestImpl(
          transaction: json['transaction'] as String,
          kind: json['kind'] as String? ?? 'Transaction',
          externalId: json['externalId'] as String?,
          $type: json['runtimeType'] as String?,
        );

Map<String, dynamic> _$$EvmTransactionHexBroadcastRequestImplToJson(
        _$EvmTransactionHexBroadcastRequestImpl instance) =>
    <String, dynamic>{
      'transaction': instance.transaction,
      'kind': instance.kind,
      if (instance.externalId case final value?) 'externalId': value,
      'runtimeType': instance.$type,
    };

_$EvmTransactionJsonBroadcastRequestImpl
    _$$EvmTransactionJsonBroadcastRequestImplFromJson(
            Map<String, dynamic> json) =>
        _$EvmTransactionJsonBroadcastRequestImpl(
          transaction: EvmTransactionJson.fromJson(
              json['transaction'] as Map<String, dynamic>),
          kind: json['kind'] as String? ?? 'Transaction',
          externalId: json['externalId'] as String?,
          $type: json['runtimeType'] as String?,
        );

Map<String, dynamic> _$$EvmTransactionJsonBroadcastRequestImplToJson(
        _$EvmTransactionJsonBroadcastRequestImpl instance) =>
    <String, dynamic>{
      'transaction': instance.transaction.toJson(),
      'kind': instance.kind,
      if (instance.externalId case final value?) 'externalId': value,
      'runtimeType': instance.$type,
    };

_$EvmUserOperationsBroadcastRequestImpl
    _$$EvmUserOperationsBroadcastRequestImplFromJson(
            Map<String, dynamic> json) =>
        _$EvmUserOperationsBroadcastRequestImpl(
          userOperations: (json['userOperations'] as List<dynamic>)
              .map((e) => EvmUserOperation.fromJson(e as Map<String, dynamic>))
              .toList(),
          feeSponsorId: json['feeSponsorId'] as String,
          kind: json['kind'] as String? ?? 'UserOperations',
          externalId: json['externalId'] as String?,
          $type: json['runtimeType'] as String?,
        );

Map<String, dynamic> _$$EvmUserOperationsBroadcastRequestImplToJson(
        _$EvmUserOperationsBroadcastRequestImpl instance) =>
    <String, dynamic>{
      'userOperations': instance.userOperations.map((e) => e.toJson()).toList(),
      'feeSponsorId': instance.feeSponsorId,
      'kind': instance.kind,
      if (instance.externalId case final value?) 'externalId': value,
      'runtimeType': instance.$type,
    };

_$EvmTransactionJsonImpl _$$EvmTransactionJsonImplFromJson(
        Map<String, dynamic> json) =>
    _$EvmTransactionJsonImpl(
      to: json['to'] as String,
      type: (json['type'] as num?)?.toInt() ?? 2,
      value: json['value'] as String?,
      data: json['data'] as String?,
      nonce: (json['nonce'] as num?)?.toInt(),
      gasLimit: json['gasLimit'] as String?,
      gasPrice: json['gasPrice'] as String?,
      maxFeePerGas: json['maxFeePerGas'] as String?,
      maxPriorityFeePerGas: json['maxPriorityFeePerGas'] as String?,
      authorizationList: (json['authorizationList'] as List<dynamic>?)
          ?.map((e) => EvmAuthorization.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$EvmTransactionJsonImplToJson(
        _$EvmTransactionJsonImpl instance) =>
    <String, dynamic>{
      'to': instance.to,
      'type': instance.type,
      if (instance.value case final value?) 'value': value,
      if (instance.data case final value?) 'data': value,
      if (instance.nonce case final value?) 'nonce': value,
      if (instance.gasLimit case final value?) 'gasLimit': value,
      if (instance.gasPrice case final value?) 'gasPrice': value,
      if (instance.maxFeePerGas case final value?) 'maxFeePerGas': value,
      if (instance.maxPriorityFeePerGas case final value?)
        'maxPriorityFeePerGas': value,
      if (instance.authorizationList?.map((e) => e.toJson()).toList()
          case final value?)
        'authorizationList': value,
    };

_$EvmUserOperationImpl _$$EvmUserOperationImplFromJson(
        Map<String, dynamic> json) =>
    _$EvmUserOperationImpl(
      to: json['to'] as String,
      value: json['value'] as String?,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$$EvmUserOperationImplToJson(
        _$EvmUserOperationImpl instance) =>
    <String, dynamic>{
      'to': instance.to,
      if (instance.value case final value?) 'value': value,
      if (instance.data case final value?) 'data': value,
    };

_$EvmAuthorizationImpl _$$EvmAuthorizationImplFromJson(
        Map<String, dynamic> json) =>
    _$EvmAuthorizationImpl(
      chainId: (json['chainId'] as num).toInt(),
      address: json['address'] as String,
      nonce: (json['nonce'] as num).toInt(),
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$$EvmAuthorizationImplToJson(
        _$EvmAuthorizationImpl instance) =>
    <String, dynamic>{
      'chainId': instance.chainId,
      'address': instance.address,
      'nonce': instance.nonce,
      'signature': instance.signature,
    };
