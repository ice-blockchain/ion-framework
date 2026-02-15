// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/tokenized_communities/data/models/tokenized_communities_trade_config.f.dart';
import 'package:ion/app/features/tokenized_communities/data/pancakeswap_v3_repository.dart';

class PancakeSwapV3Service {
  PancakeSwapV3Service({
    required this.repository,
    required this.tradeConfig,
  });

  final PancakeSwapV3Repository repository;
  final TokenizedCommunitiesTradeConfig tradeConfig;
  bool _routerCompatibilityChecked = false;
  static const List<int> _fallbackFeeTiers = [100, 500, 2500, 10000];

  static const _nativeTokenAddress = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  String get ionTokenAddress => tradeConfig.pancakeSwapIonTokenAddress;

  String get wbnbTokenAddress => tradeConfig.pancakeSwapWbnbAddress;

  int get feeTier => tradeConfig.pancakeSwapFeeTier;

  String get swapRouterAddress => tradeConfig.pancakeSwapSwapRouterAddress;

  bool isNativeTokenAddress(String address) {
    return address.toLowerCase() == _nativeTokenAddress || address.toLowerCase() == 'bnb';
  }

  Future<void> ensureRouterCompatibility() async {
    if (_routerCompatibilityChecked) return;

    final expectedWbnb = wbnbTokenAddress.toLowerCase();
    final routerAddress = swapRouterAddress;

    try {
      final routerWeth9 = (await repository.fetchRouterWeth9Address()).toLowerCase();
      if (routerWeth9 != expectedWbnb) {
        throw PancakeSwapRouterMisconfiguredException(
          'WETH9 mismatch. router=$routerAddress WETH9=$routerWeth9 expected=$expectedWbnb',
        );
      }
    } catch (error) {
      if (error is PancakeSwapRouterMisconfiguredException) rethrow;
      throw PancakeSwapRouterMisconfiguredException(
        'WETH9 probe failed for router=$routerAddress error=$error',
      );
    }

    try {
      final routerFactory = (await repository.fetchRouterFactoryAddress()).toLowerCase();
      final quoterFactory = (await repository.fetchQuoterFactoryAddress()).toLowerCase();
      if (routerFactory != quoterFactory) {
        throw PancakeSwapRouterMisconfiguredException(
          'Factory mismatch. router=$routerAddress routerFactory=$routerFactory quoterFactory=$quoterFactory',
        );
      }
    } catch (error) {
      if (error is PancakeSwapRouterMisconfiguredException) rethrow;
      throw PancakeSwapRouterMisconfiguredException(
        'Factory probe failed for router=$routerAddress error=$error',
      );
    }

    try {
      await repository.probeExactInputSingle(
        tokenIn: wbnbTokenAddress,
        tokenOut: ionTokenAddress,
        fee: feeTier,
        recipient: routerAddress,
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('invalid nft position manager') ||
          message.contains('function selector was not recognized')) {
        throw PancakeSwapRouterMisconfiguredException(
          'exactInputSingle probe failed for router=$routerAddress error=$error',
        );
      }
      // AS/SPL/no-pool style reverts still mean router ABI/selector are compatible.
    }

    _routerCompatibilityChecked = true;
  }

  Future<({BigInt amountIn, int fee})> getQuoteForExactOutput({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountOut,
  }) async {
    await ensureRouterCompatibility();
    final effectiveTokenIn = isNativeTokenAddress(tokenIn) ? wbnbTokenAddress : tokenIn;
    final effectiveTokenOut = isNativeTokenAddress(tokenOut) ? wbnbTokenAddress : tokenOut;
    final candidates = _resolveFeeTierCandidates();

    for (final feeCandidate in candidates) {
      try {
        final amountIn = await repository.quoteExactOutputSingle(
          tokenIn: effectiveTokenIn,
          tokenOut: effectiveTokenOut,
          amountOut: amountOut,
          fee: feeCandidate,
        );
        return (amountIn: amountIn, fee: feeCandidate);
      } catch (error) {
        if (_looksLikeNoPoolError(error)) {
          continue;
        }
        rethrow;
      }
    }

    throw LiquidityPoolNotFoundException(tokenIn: tokenIn, tokenOut: tokenOut);
  }

  Future<({BigInt amountOut, int fee})> getQuoteForExactInput({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountIn,
  }) async {
    await ensureRouterCompatibility();
    final effectiveTokenIn = isNativeTokenAddress(tokenIn) ? wbnbTokenAddress : tokenIn;
    final effectiveTokenOut = isNativeTokenAddress(tokenOut) ? wbnbTokenAddress : tokenOut;
    final candidates = _resolveFeeTierCandidates();

    for (final feeCandidate in candidates) {
      try {
        final amountOut = await repository.quoteExactInputSingle(
          tokenIn: effectiveTokenIn,
          tokenOut: effectiveTokenOut,
          amountIn: amountIn,
          fee: feeCandidate,
        );
        return (amountOut: amountOut, fee: feeCandidate);
      } catch (error) {
        if (_looksLikeNoPoolError(error)) {
          continue;
        }
        rethrow;
      }
    }

    throw LiquidityPoolNotFoundException(tokenIn: tokenIn, tokenOut: tokenOut);
  }

  bool _looksLikeNoPoolError(Object error) {
    final message = error.toString().toLowerCase();
    return (message.contains('pool') && message.contains('not')) ||
        message.contains('no liquidity') ||
        message.contains('liquidity pool') ||
        message.contains('execution reverted: 0x') ||
        message.contains('execution reverted: spl') ||
        message.contains('execution reverted: unexpected error');
  }

  List<int> _resolveFeeTierCandidates() {
    final configured = tradeConfig.pancakeSwapFeeTier;
    final candidates = <int>[
      configured,
      ..._fallbackFeeTiers,
    ];
    final unique = <int>[];
    for (final candidate in candidates) {
      if (!unique.contains(candidate)) {
        unique.add(candidate);
      }
    }
    return unique;
  }
}
