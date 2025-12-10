// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swap_quote_info.m.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwapQuoteInfoImpl _$$SwapQuoteInfoImplFromJson(Map<String, dynamic> json) => _$SwapQuoteInfoImpl(
      type: $enumDecode(_$SwapQuoteInfoTypeEnumMap, json['type']),
      priceForSellTokenInBuyToken: (json['priceForSellTokenInBuyToken'] as num).toDouble(),
      source: $enumDecode(_$SwapQuoteInfoSourceEnumMap, json['source']),
      swapImpact: (json['swapImpact'] as num?)?.toInt(),
      networkFee: json['networkFee'] as String?,
      protocolFee: json['protocolFee'] as String?,
      exolixQuote: json['exolixQuote'] == null
          ? null
          : ExolixRate.fromJson(json['exolixQuote'] as Map<String, dynamic>),
      letsExchangeQuote: json['letsExchangeQuote'] == null
          ? null
          : LetsExchangeInfo.fromJson(json['letsExchangeQuote'] as Map<String, dynamic>),
      okxQuote: json['okxQuote'] == null
          ? null
          : SwapQuoteData.fromJson(json['okxQuote'] as Map<String, dynamic>),
      relayQuote: json['relayQuote'] == null
          ? null
          : RelayQuote.fromJson(json['relayQuote'] as Map<String, dynamic>),
      relayDepositAmount: json['relayDepositAmount'] as String?,
    );

Map<String, dynamic> _$$SwapQuoteInfoImplToJson(_$SwapQuoteInfoImpl instance) => <String, dynamic>{
      'type': _$SwapQuoteInfoTypeEnumMap[instance.type]!,
      'priceForSellTokenInBuyToken': instance.priceForSellTokenInBuyToken,
      'source': _$SwapQuoteInfoSourceEnumMap[instance.source]!,
      'swapImpact': instance.swapImpact,
      'networkFee': instance.networkFee,
      'protocolFee': instance.protocolFee,
      'exolixQuote': instance.exolixQuote,
      'letsExchangeQuote': instance.letsExchangeQuote,
      'okxQuote': instance.okxQuote,
      'relayQuote': instance.relayQuote,
      'relayDepositAmount': instance.relayDepositAmount,
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
  SwapQuoteInfoSource.ionOnchain: 'ionOnchain',
};
