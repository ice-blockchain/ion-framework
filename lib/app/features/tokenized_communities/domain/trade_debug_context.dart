// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/trade_quote_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/transaction_result.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeDebugContext {
  TradeDebugContext({
    required this.mode,
    required this.externalAddress,
    required this.externalAddressType,
    required this.walletId,
    required this.walletAddress,
    required this.walletNetwork,
    required this.amountIn,
    required this.expectedPricing,
    required this.slippagePercent,
    required this.shouldSendEvents,
    this.baseTokenAddress,
    this.baseTokenTicker,
    this.baseTokenDecimals,
    this.paymentTokenAddress,
    this.paymentTokenTicker,
    this.paymentTokenDecimals,
    this.communityTokenAddress,
    this.existingTokenAddress,
    this.firstBuy,
    this.hasUserPosition,
    this.isCreatorTokenMissingForContentFirstBuy,
    this.fatAddressData,
    this.route,
    this.quote,
    this.userOperations,
    this.transaction,
  });

  final CommunityTokenTradeMode mode;
  final String externalAddress;
  final ExternalAddressType externalAddressType;
  final String walletId;
  final String walletAddress;
  final String walletNetwork;
  final BigInt amountIn;
  final PricingResponse expectedPricing;
  final double slippagePercent;
  final bool shouldSendEvents;
  final String? baseTokenAddress;
  final String? baseTokenTicker;
  final int? baseTokenDecimals;
  final String? paymentTokenAddress;
  final String? paymentTokenTicker;
  final int? paymentTokenDecimals;
  final String? communityTokenAddress;
  final String? existingTokenAddress;
  final bool? firstBuy;
  final bool? hasUserPosition;
  final bool? isCreatorTokenMissingForContentFirstBuy;
  final FatAddressV2Data? fatAddressData;
  final TradeRoutePlan? route;
  final TradeQuotePlan? quote;
  final List<EvmUserOperation>? userOperations;
  final TransactionResult? transaction;

  Map<String, dynamic> toJson() {
    return {
      'tradeMode': mode.name,
      'externalAddress': externalAddress,
      'externalAddressTypePrefix': externalAddressType.prefix,
      'isCreatorToken': externalAddressType.isCreatorToken,
      'isContentToken': externalAddressType.isContentToken,
      'isXToken': externalAddressType.isXToken,
      'walletId': walletId,
      'walletAddress': _maskAddress(walletAddress),
      'walletNetwork': walletNetwork,
      'requestedAmountIn': amountIn.toString(),
      'slippagePercent': slippagePercent,
      'shouldSendEvents': shouldSendEvents,
      if (baseTokenAddress != null) 'baseTokenAddress': baseTokenAddress,
      if (baseTokenTicker != null) 'baseTokenTicker': baseTokenTicker,
      if (baseTokenDecimals != null) 'baseTokenDecimals': baseTokenDecimals,
      if (paymentTokenAddress != null) 'paymentTokenAddress': paymentTokenAddress,
      if (paymentTokenTicker != null) 'paymentTokenTicker': paymentTokenTicker,
      if (paymentTokenDecimals != null) 'paymentTokenDecimals': paymentTokenDecimals,
      if (communityTokenAddress != null) 'communityTokenAddress': communityTokenAddress,
      if (existingTokenAddress != null) 'existingTokenAddress': existingTokenAddress,
      if (firstBuy != null) 'firstBuy': firstBuy,
      if (hasUserPosition != null) 'hasUserPosition': hasUserPosition,
      if (isCreatorTokenMissingForContentFirstBuy != null)
        'isCreatorTokenMissingForContentFirstBuy': isCreatorTokenMissingForContentFirstBuy,
      'expectedPricing': _serializePricing(expectedPricing),
      if (fatAddressData != null) 'fatAddress': _maskHex(fatAddressData!.toHex()),
      if (route != null) 'route': _serializeRoute(route!),
      if (quote != null) 'quote': _serializeQuote(quote!),
      if (userOperations != null) 'userOperations': _serializeUserOperations(userOperations!),
      if (transaction != null) 'transaction': _serializeTransaction(transaction!),
    };
  }
}

Map<String, dynamic> _serializePricing(PricingResponse pricing) {
  return {
    'amount': pricing.amount,
    'amountUSD': pricing.amountUSD,
    'feeSponsorId': pricing.feeSponsorId,
    if (pricing.bondingCurveAlgAddress != null)
      'bondingCurveAlgAddress': pricing.bondingCurveAlgAddress,
  };
}

List<Map<String, dynamic>> _serializeRoute(TradeRoutePlan route) {
  return route.steps
      .map(
        (step) => {
          'type': step.type.name,
          'fromRole': step.fromRole.name,
          'toRole': step.toRole.name,
          if (step.mode != null) 'mode': step.mode!.name,
          if (step.externalAddress != null) 'externalAddress': step.externalAddress,
        },
      )
      .toList();
}

List<Map<String, dynamic>> _serializeQuote(TradeQuotePlan quote) {
  return quote.steps
      .map(
        (step) => {
          'type': step.step.type.name,
          'fromRole': step.step.fromRole.name,
          'toRole': step.step.toRole.name,
          if (step.step.mode != null) 'mode': step.step.mode!.name,
          if (step.step.externalAddress != null) 'externalAddress': step.step.externalAddress,
          'amountIn': step.amountIn.toString(),
          'amountOut': step.amountOut.toString(),
          'minReturn': step.minReturn.toString(),
          if (step.pancakeSwapFeeTier != null) 'pancakeSwapFeeTier': step.pancakeSwapFeeTier,
        },
      )
      .toList();
}

List<Map<String, dynamic>> _serializeUserOperations(List<EvmUserOperation> userOperations) {
  return userOperations
      .map(
        (operation) => {
          'to': operation.to,
          'hasValue': operation.value != null,
          'dataLength': operation.data?.length ?? 0,
        },
      )
      .toList();
}

Map<String, dynamic> _serializeTransaction(TransactionResult transaction) {
  return {
    if (transaction['id'] != null) 'id': transaction['id'],
    if (transaction['status'] != null) 'status': transaction['status'],
    if (transaction['reason'] != null) 'reason': transaction['reason'],
    if (transaction['txHash'] != null) 'txHash': _maskAddress(transaction['txHash']?.toString()),
    if (transaction['network'] != null) 'network': transaction['network'],
  };
}

String? _maskAddress(String? value) {
  final normalized = _nonEmptyString(value);
  if (normalized == null) {
    return null;
  }
  if (!normalized.startsWith('0x') || normalized.length < 12) {
    return normalized;
  }
  return '${normalized.substring(0, 6)}...${normalized.substring(normalized.length - 4)}';
}

String _maskHex(String value) {
  final normalized = value.trim();
  if (!normalized.startsWith('0x') || normalized.length < 18) {
    return normalized;
  }
  return '${normalized.substring(0, 10)}...${normalized.substring(normalized.length - 8)}';
}

String? _nonEmptyString(Object? value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
