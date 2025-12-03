// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_quote_info.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapQuoteInfoImpl _$$SwapQuoteInfoImplFromJson(Map<String, dynamic> json) =>
    _$SwapQuoteInfoImpl(
      type: $enumDecode(_$SwapQuoteInfoTypeEnumMap, json['type']),
      priceForSellTokenInBuyToken:
          (json['priceForSellTokenInBuyToken'] as num).toDouble(),
      source: $enumDecode(_$SwapQuoteInfoSourceEnumMap, json['source']),
      swapImpact: (json['swapImpact'] as num?)?.toInt(),
      networkFee: json['networkFee'] as String?,
      protocolFee: json['protocolFee'] as String?,
      slippage: json['slippage'] as String?,
    );

Map<String, dynamic> _$$SwapQuoteInfoImplToJson(_$SwapQuoteInfoImpl instance) =>
    <String, dynamic>{
      'type': _$SwapQuoteInfoTypeEnumMap[instance.type]!,
      'priceForSellTokenInBuyToken': instance.priceForSellTokenInBuyToken,
      'source': _$SwapQuoteInfoSourceEnumMap[instance.source]!,
      'swapImpact': instance.swapImpact,
      'networkFee': instance.networkFee,
      'protocolFee': instance.protocolFee,
      'slippage': instance.slippage,
    };

const _$SwapQuoteInfoTypeEnumMap = {
  SwapQuoteInfoType.cexOrDex: 'cexOrDex',
  SwapQuoteInfoType.bridge: 'bridge',
};

const _$SwapQuoteInfoSourceEnumMap = {
  SwapQuoteInfoSource.exolix: 'exolix',
  SwapQuoteInfoSource.letsExchange: 'letsExchange',
  SwapQuoteInfoSource.okx: 'okx',
  SwapQuoteInfoSource.relay: 'relay',
};
