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
    );

Map<String, dynamic> _$$SwapQuoteInfoImplToJson(_$SwapQuoteInfoImpl instance) =>
    <String, dynamic>{
      'type': _$SwapQuoteInfoTypeEnumMap[instance.type]!,
      'priceForSellTokenInBuyToken': instance.priceForSellTokenInBuyToken,
      'source': _$SwapQuoteInfoSourceEnumMap[instance.source]!,
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
