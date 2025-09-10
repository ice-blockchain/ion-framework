// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_history_record.f.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletHistoryRecordImpl _$$WalletHistoryRecordImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletHistoryRecordImpl(
      walletId: json['walletId'] as String,
      network: json['network'] as String,
      kind: json['kind'] as String,
      direction: json['direction'] as String,
      blockNumber: (json['blockNumber'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      txHash: json['txHash'] as String,
      externalHash: json['externalHash'] as String?,
      index: json['index'] as String?,
      contract: json['contract'] as String?,
      metadataAddress: json['metadataAddress'] as String?,
      tokenId: json['tokenId'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      tos: (json['tos'] as List<dynamic>?)?.map((e) => e as String).toList(),
      froms:
          (json['froms'] as List<dynamic>?)?.map((e) => e as String).toList(),
      value: json['value'] as String?,
      fee: json['fee'] as String?,
      memo: json['memo'] as String?,
      metadata: WalletHistoryMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WalletHistoryRecordImplToJson(
        _$WalletHistoryRecordImpl instance) =>
    <String, dynamic>{
      'walletId': instance.walletId,
      'network': instance.network,
      'kind': instance.kind,
      'direction': instance.direction,
      'blockNumber': instance.blockNumber,
      'timestamp': instance.timestamp.toIso8601String(),
      'txHash': instance.txHash,
      if (instance.externalHash case final value?) 'externalHash': value,
      if (instance.index case final value?) 'index': value,
      if (instance.contract case final value?) 'contract': value,
      if (instance.metadataAddress case final value?) 'metadataAddress': value,
      if (instance.tokenId case final value?) 'tokenId': value,
      if (instance.from case final value?) 'from': value,
      if (instance.to case final value?) 'to': value,
      if (instance.tos case final value?) 'tos': value,
      if (instance.froms case final value?) 'froms': value,
      if (instance.value case final value?) 'value': value,
      if (instance.fee case final value?) 'fee': value,
      if (instance.memo case final value?) 'memo': value,
      'metadata': instance.metadata.toJson(),
    };
