// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_user_ops_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_trade_config.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_ops_support.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_quote_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/utils/hex_encoding.dart';
import 'package:ion_identity_client/ion_identity.dart';

class TradeUserOpsBuilder {
  TradeUserOpsBuilder({
    required TradeCommunityTokenRepository repository,
    required PancakeSwapV3Service pancakeSwapService,
    required PancakeSwapV3UserOpsBuilder pancakeSwapUserOpsBuilder,
    required TradeOpsSupport support,
    required TokenizedCommunitiesTradeConfig tradeConfig,
  })  : _repository = repository,
        _pancakeSwapService = pancakeSwapService,
        _pancakeSwapUserOpsBuilder = pancakeSwapUserOpsBuilder,
        _support = support,
        _tradeConfig = tradeConfig;

  final TradeCommunityTokenRepository _repository;
  final PancakeSwapV3Service _pancakeSwapService;
  final PancakeSwapV3UserOpsBuilder _pancakeSwapUserOpsBuilder;
  final TradeOpsSupport _support;
  final TokenizedCommunitiesTradeConfig _tradeConfig;

  Future<List<EvmUserOperation>> buildUserOps({
    required TradeRoutePlan route,
    required TradeQuotePlan quote,
    required String walletAddress,
    required String paymentTokenAddress,
    required int paymentTokenDecimals,
    required int communityTokenDecimals,
    String? communityTokenAddress,
    FatAddressV2Data? fatAddressData,
  }) async {
    final opsPerStep = await Future.wait(
      quote.steps.map(
        (quoteStep) => _buildUserOpsForStep(
          quoteStep: quoteStep,
          route: route,
          walletAddress: walletAddress,
          paymentTokenAddress: paymentTokenAddress,
          paymentTokenDecimals: paymentTokenDecimals,
          communityTokenDecimals: communityTokenDecimals,
          communityTokenAddress: communityTokenAddress,
          fatAddressData: fatAddressData,
        ),
      ),
    );
    return opsPerStep.expand((ops) => ops).toList();
  }

  Future<List<EvmUserOperation>> _buildUserOpsForStep({
    required TradeQuoteStep quoteStep,
    required TradeRoutePlan route,
    required String walletAddress,
    required String paymentTokenAddress,
    required int paymentTokenDecimals,
    required int communityTokenDecimals,
    required String? communityTokenAddress,
    required FatAddressV2Data? fatAddressData,
  }) async {
    final step = quoteStep.step;
    if (step.type == TradeRouteStepType.pancakeSwap) {
      return _buildPancakeSwapUserOps(
        quoteStep: quoteStep,
        step: step,
        route: route,
        walletAddress: walletAddress,
        paymentTokenAddress: paymentTokenAddress,
        paymentTokenDecimals: paymentTokenDecimals,
        communityTokenAddress: communityTokenAddress,
      );
    }
    return _buildBondingCurveUserOps(
      quoteStep: quoteStep,
      step: step,
      route: route,
      walletAddress: walletAddress,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenDecimals: paymentTokenDecimals,
      communityTokenDecimals: communityTokenDecimals,
      communityTokenAddress: communityTokenAddress,
      fatAddressData: fatAddressData,
    );
  }

  Future<List<EvmUserOperation>> _buildPancakeSwapUserOps({
    required TradeQuoteStep quoteStep,
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String walletAddress,
    required String paymentTokenAddress,
    required int paymentTokenDecimals,
    required String? communityTokenAddress,
  }) async {
    final tokenIn = await _resolveAddressForRole(
      role: step.fromRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
      communityTokenAddress: communityTokenAddress,
    );
    final tokenOut = await _resolveAddressForRole(
      role: step.toRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
      communityTokenAddress: communityTokenAddress,
    );
    final approvalOp = await _buildPancakeSwapApprovalIfNeeded(
      owner: walletAddress,
      tokenIn: tokenIn,
      amountIn: quoteStep.amountIn,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenDecimals: paymentTokenDecimals,
    );
    return _pancakeSwapUserOpsBuilder.buildSwapOperations(
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountIn: quoteStep.amountIn,
      amountOutMinimum: quoteStep.minReturn,
      recipient: walletAddress,
      isNativeIn: _pancakeSwapService.isNativeTokenAddress(tokenIn),
      isNativeOut: _pancakeSwapService.isNativeTokenAddress(tokenOut),
      approvalOperation: approvalOp,
    );
  }

  Future<List<EvmUserOperation>> _buildBondingCurveUserOps({
    required TradeQuoteStep quoteStep,
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String walletAddress,
    required String paymentTokenAddress,
    required int paymentTokenDecimals,
    required int communityTokenDecimals,
    required String? communityTokenAddress,
    required FatAddressV2Data? fatAddressData,
  }) async {
    final fromTokenAddress = await _resolveAddressForRole(
      role: step.fromRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
      communityTokenAddress: communityTokenAddress,
    );
    final toTokenAddress = await _resolveAddressForRole(
      role: step.toRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
      communityTokenAddress: communityTokenAddress,
    );
    final approvalOp = await _buildBondingCurveApprovalIfNeeded(
      fromTokenAddress: fromTokenAddress,
      quoteStep: quoteStep,
      step: step,
      walletAddress: walletAddress,
      paymentTokenDecimals: paymentTokenDecimals,
      communityTokenDecimals: communityTokenDecimals,
    );
    final toTokenBytes = await _resolveBondingCurveToTokenBytes(
      step: step,
      route: route,
      toTokenAddress: toTokenAddress,
      fatAddressData: fatAddressData,
    );
    final swapOp = await _repository.buildSwapUserOperation(
      fromTokenIdentifier: getBytesFromAddress(fromTokenAddress),
      toTokenIdentifier: toTokenBytes,
      amountIn: quoteStep.amountIn,
      minReturn: quoteStep.minReturn,
    );
    if (approvalOp == null) {
      return [swapOp];
    }
    return [approvalOp, swapOp];
  }

  Future<EvmUserOperation?> _buildBondingCurveApprovalIfNeeded({
    required String fromTokenAddress,
    required TradeQuoteStep quoteStep,
    required TradeRouteStep step,
    required String walletAddress,
    required int paymentTokenDecimals,
    required int communityTokenDecimals,
  }) async {
    if (!_isEvmAddress(fromTokenAddress)) {
      return null;
    }
    return _support.buildAllowanceApprovalOperationIfNeeded(
      owner: walletAddress,
      tokenAddress: fromTokenAddress,
      requiredAmount: quoteStep.amountIn,
      tokenDecimals: _resolveTokenDecimals(
        role: step.fromRole,
        paymentTokenDecimals: paymentTokenDecimals,
        communityTokenDecimals: communityTokenDecimals,
      ),
    );
  }

  Future<List<int>> _resolveBondingCurveToTokenBytes({
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String toTokenAddress,
    required FatAddressV2Data? fatAddressData,
  }) async {
    if (step.mode == CommunityTokenTradeMode.sell) {
      return getBytesFromAddress(toTokenAddress);
    }
    final tokenAddress = await _resolveOptionalCommunityTokenAddress(
      role: step.toRole,
      route: route,
    );
    return _support.buildBuyToTokenBytes(
      externalAddress: step.externalAddress!,
      tokenAddress: tokenAddress,
      fatAddressData: fatAddressData,
    );
  }

  Future<EvmUserOperation?> _buildPancakeSwapApprovalIfNeeded({
    required String owner,
    required String tokenIn,
    required BigInt amountIn,
    required String paymentTokenAddress,
    required int paymentTokenDecimals,
  }) async {
    if (_pancakeSwapService.isNativeTokenAddress(tokenIn)) {
      return null;
    }
    final decimals = tokenIn == _tradeConfig.pancakeSwapIonTokenAddress
        ? _tradeConfig.ionTokenDecimals
        : paymentTokenDecimals;
    return _support.buildAllowanceApprovalOperationIfNeeded(
      owner: owner,
      tokenAddress: tokenIn,
      requiredAmount: amountIn,
      tokenDecimals: decimals,
      spender: _tradeConfig.pancakeSwapSwapRouterAddress,
    );
  }

  Future<String> _resolveAddressForRole({
    required TradeTokenRole role,
    required TradeRoutePlan route,
    required String paymentTokenAddress,
    required String? communityTokenAddress,
  }) async {
    return switch (role) {
      TradeTokenRole.payment => paymentTokenAddress,
      TradeTokenRole.ion => _tradeConfig.pancakeSwapIonTokenAddress,
      TradeTokenRole.creator => await _resolveCreatorTokenAddress(route, communityTokenAddress),
      TradeTokenRole.content => await _resolveContentTokenAddress(route, communityTokenAddress),
    };
  }

  Future<String> _resolveCreatorTokenAddress(
    TradeRoutePlan route,
    String? communityTokenAddress,
  ) async {
    if (!route.externalAddressType.isContentToken) {
      return communityTokenAddress ?? await _resolveTokenIdentifier(route.externalAddress);
    }
    return _resolveTokenIdentifier(route.creatorExternalAddress!);
  }

  Future<String> _resolveContentTokenAddress(
    TradeRoutePlan route,
    String? communityTokenAddress,
  ) async {
    return communityTokenAddress ?? await _resolveTokenIdentifier(route.externalAddress);
  }

  Future<String?> _resolveOptionalCommunityTokenAddress({
    required TradeTokenRole role,
    required TradeRoutePlan route,
  }) async {
    return switch (role) {
      TradeTokenRole.creator => await _resolveOptionalTokenAddress(
          route.creatorExternalAddress ?? route.externalAddress,
        ),
      TradeTokenRole.content => await _resolveOptionalTokenAddress(route.externalAddress),
      _ => null,
    };
  }

  Future<String> _resolveTokenIdentifier(String externalAddress) async {
    final info = await _repository.fetchTokenInfo(externalAddress);
    final address = info?.addresses.blockchain?.trim() ?? '';
    if (address.isEmpty) {
      return externalAddress;
    }
    return address;
  }

  Future<String?> _resolveOptionalTokenAddress(String externalAddress) async {
    final info = await _repository.fetchTokenInfo(externalAddress);
    final address = info?.addresses.blockchain?.trim() ?? '';
    if (address.isEmpty) {
      return null;
    }
    return address;
  }

  bool _isEvmAddress(String value) {
    final normalized = value.trim();
    return normalized.startsWith('0x') && normalized.length >= 42;
  }

  int _resolveTokenDecimals({
    required TradeTokenRole role,
    required int paymentTokenDecimals,
    required int communityTokenDecimals,
  }) {
    return switch (role) {
      TradeTokenRole.payment => paymentTokenDecimals,
      TradeTokenRole.ion => _tradeConfig.ionTokenDecimals,
      TradeTokenRole.creator => communityTokenDecimals,
      TradeTokenRole.content => communityTokenDecimals,
    };
  }
}
