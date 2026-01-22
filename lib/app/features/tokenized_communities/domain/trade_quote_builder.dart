// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/pancakeswap_v3_service.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_ops_support.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeQuoteStep {
  const TradeQuoteStep({
    required this.step,
    required this.amountIn,
    required this.amountOut,
    required this.minReturn,
  });

  final TradeRouteStep step;
  final BigInt amountIn;
  final BigInt amountOut;
  final BigInt minReturn;
}

class TradeQuotePlan {
  const TradeQuotePlan({
    required this.steps,
    required this.finalPricing,
  });

  final List<TradeQuoteStep> steps;
  final PricingResponse finalPricing;
}

class TradeQuoteBuilder {
  TradeQuoteBuilder({
    required TradeCommunityTokenRepository repository,
    required PancakeSwapV3Service pancakeSwapService,
    required TradeOpsSupport support,
  })  : _repository = repository,
        _pancakeSwapService = pancakeSwapService,
        _support = support;

  final TradeCommunityTokenRepository _repository;
  final PancakeSwapV3Service _pancakeSwapService;
  final TradeOpsSupport _support;

  Future<TradeQuotePlan> build({
    required TradeRoutePlan route,
    required String pricingIdentifier,
    required BigInt amountIn,
    required String paymentTokenAddress,
    required double slippagePercent,
    String? fatAddressHex,
  }) async {
    var state = _QuoteBuildState.initial(amountIn);
    for (final step in route.steps) {
      state = await _appendQuoteStep(
        state: state,
        step: step,
        route: route,
        pricingIdentifier: pricingIdentifier,
        paymentTokenAddress: paymentTokenAddress,
        slippagePercent: slippagePercent,
        fatAddressHex: fatAddressHex,
      );
    }

    final finalPricing = _resolveFinalPricing(
      route: route,
      finalAmount: state.currentAmount,
      lastBondingCurvePricing: state.lastBondingCurvePricing,
    );
    return TradeQuotePlan(
      steps: state.steps,
      finalPricing: finalPricing,
    );
  }

  Future<_QuoteBuildState> _appendQuoteStep({
    required _QuoteBuildState state,
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String pricingIdentifier,
    required String paymentTokenAddress,
    required double slippagePercent,
    required String? fatAddressHex,
  }) async {
    if (step.type == TradeRouteStepType.pancakeSwap) {
      final quoteStep = await _buildPancakeSwapQuoteStep(
        step: step,
        route: route,
        paymentTokenAddress: paymentTokenAddress,
        amountIn: state.currentAmount,
        slippagePercent: slippagePercent,
      );
      return state.withStep(
        step: quoteStep,
        nextAmount: quoteStep.amountOut,
      );
    }

    final quoteStep = await _buildBondingCurveQuoteStep(
      step: step,
      route: route,
      pricingIdentifier: pricingIdentifier,
      amountIn: state.currentAmount,
      slippagePercent: slippagePercent,
      fatAddressHex: fatAddressHex,
    );
    return state.withStep(
      step: quoteStep.step,
      nextAmount: quoteStep.step.amountOut,
      lastBondingCurvePricing: quoteStep.pricing,
    );
  }

  Future<_BondingCurveQuoteStep> _buildBondingCurveQuoteStep({
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String pricingIdentifier,
    required BigInt amountIn,
    required double slippagePercent,
    required String? fatAddressHex,
  }) async {
    final mode = step.mode!;
    final stepPricingIdentifier = await _resolvePricingIdentifier(
      step: step,
      route: route,
      providedPricingIdentifier: pricingIdentifier,
      fatAddressHex: fatAddressHex,
    );
    final pricing = await _repository.fetchPricing(
      pricingIdentifier: stepPricingIdentifier,
      mode: mode,
      amount: amountIn.toString(),
    );
    final amountOut = BigInt.parse(pricing.amount);
    final minReturn = _support.calculateMinReturn(
      expectedOut: amountOut,
      slippagePercent: slippagePercent,
    );
    return _BondingCurveQuoteStep(
      step: TradeQuoteStep(
        step: step,
        amountIn: amountIn,
        amountOut: amountOut,
        minReturn: minReturn,
      ),
      pricing: pricing,
    );
  }

  Future<TradeQuoteStep> _buildPancakeSwapQuoteStep({
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String paymentTokenAddress,
    required BigInt amountIn,
    required double slippagePercent,
  }) async {
    final tokenIn = _resolveRoleAddress(
      role: step.fromRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
    );
    final tokenOut = _resolveRoleAddress(
      role: step.toRole,
      route: route,
      paymentTokenAddress: paymentTokenAddress,
    );
    final quote = await _pancakeSwapService.getQuoteForExactInput(
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountIn: amountIn,
    );
    final amountOut = quote.amountOut;
    final minReturn = _support.calculateMinReturn(
      expectedOut: amountOut,
      slippagePercent: slippagePercent,
    );
    return TradeQuoteStep(
      step: step,
      amountIn: amountIn,
      amountOut: amountOut,
      minReturn: minReturn,
    );
  }

  String _resolveRoleAddress({
    required TradeTokenRole role,
    required TradeRoutePlan route,
    required String paymentTokenAddress,
  }) {
    return switch (role) {
      TradeTokenRole.payment => paymentTokenAddress,
      TradeTokenRole.ion => _pancakeSwapService.ionTokenAddress,
      TradeTokenRole.creator => route.creatorExternalAddress ?? route.externalAddress,
      TradeTokenRole.content => route.externalAddress,
    };
  }

  Future<String> _resolvePricingIdentifier({
    required TradeRouteStep step,
    required TradeRoutePlan route,
    required String providedPricingIdentifier,
    String? fatAddressHex,
  }) async {
    final externalAddress = step.externalAddress!;
    if (externalAddress == route.externalAddress) {
      return providedPricingIdentifier;
    }

    if (externalAddress == route.creatorExternalAddress) {
      final tokenInfo = await _repository.fetchTokenInfo(externalAddress);
      final tokenAddress = tokenInfo?.addresses.blockchain?.trim() ?? '';
      if (tokenAddress.isNotEmpty) {
        return externalAddress;
      }
      final fatHex = fatAddressHex ?? '';
      if (fatHex.isNotEmpty) {
        return fatHex;
      }
    }

    return externalAddress;
  }

  PricingResponse _resolveFinalPricing({
    required TradeRoutePlan route,
    required BigInt finalAmount,
    required PricingResponse? lastBondingCurvePricing,
  }) {
    if (lastBondingCurvePricing == null) {
      throw StateError('Bonding curve pricing is missing for trade quote.');
    }

    final hasFinalPancakeSwap =
        route.steps.isNotEmpty && route.steps.last.type == TradeRouteStepType.pancakeSwap;
    if (!hasFinalPancakeSwap) {
      return lastBondingCurvePricing;
    }

    return lastBondingCurvePricing.copyWith(
      amount: finalAmount.toString(),
    );
  }
}

class _QuoteBuildState {
  const _QuoteBuildState({
    required this.currentAmount,
    required this.steps,
    required this.lastBondingCurvePricing,
  });

  factory _QuoteBuildState.initial(BigInt amountIn) {
    return _QuoteBuildState(
      currentAmount: amountIn,
      steps: const [],
      lastBondingCurvePricing: null,
    );
  }

  final BigInt currentAmount;
  final List<TradeQuoteStep> steps;
  final PricingResponse? lastBondingCurvePricing;

  _QuoteBuildState withStep({
    required TradeQuoteStep step,
    required BigInt nextAmount,
    PricingResponse? lastBondingCurvePricing,
  }) {
    return _QuoteBuildState(
      currentAmount: nextAmount,
      steps: [...steps, step],
      lastBondingCurvePricing: lastBondingCurvePricing ?? this.lastBondingCurvePricing,
    );
  }
}

class _BondingCurveQuoteStep {
  const _BondingCurveQuoteStep({
    required this.step,
    required this.pricing,
  });

  final TradeQuoteStep step;
  final PricingResponse pricing;
}
