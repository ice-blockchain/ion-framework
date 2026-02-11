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

  static const _nativeTokenAddress = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  String get ionTokenAddress => tradeConfig.pancakeSwapIonTokenAddress;

  String get wbnbTokenAddress => tradeConfig.pancakeSwapWbnbAddress;

  int get feeTier => tradeConfig.pancakeSwapFeeTier;

  String get swapRouterAddress => tradeConfig.pancakeSwapSwapRouterAddress;

  bool isIonTokenAddress(String address) {
    return address.toLowerCase() == ionTokenAddress.toLowerCase();
  }

  bool isNativeTokenAddress(String address) {
    return address.toLowerCase() == _nativeTokenAddress || address.toLowerCase() == 'bnb';
  }

  Future<({BigInt amountIn, int fee})> getQuoteForExactOutput({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountOut,
  }) async {
    final effectiveTokenIn = isNativeTokenAddress(tokenIn) ? wbnbTokenAddress : tokenIn;
    final effectiveTokenOut = isNativeTokenAddress(tokenOut) ? wbnbTokenAddress : tokenOut;

    try {
      final amountIn = await repository.quoteExactOutputSingle(
        tokenIn: effectiveTokenIn,
        tokenOut: effectiveTokenOut,
        amountOut: amountOut,
        fee: feeTier,
      );
      return (amountIn: amountIn, fee: feeTier);
    } catch (error) {
      if (_looksLikeNoPoolError(error)) {
        throw LiquidityPoolNotFoundException(tokenIn: tokenIn, tokenOut: tokenOut);
      }
      rethrow;
    }
  }

  Future<({BigInt amountOut, int fee})> getQuoteForExactInput({
    required String tokenIn,
    required String tokenOut,
    required BigInt amountIn,
  }) async {
    final effectiveTokenIn = isNativeTokenAddress(tokenIn) ? wbnbTokenAddress : tokenIn;
    final effectiveTokenOut = isNativeTokenAddress(tokenOut) ? wbnbTokenAddress : tokenOut;

    try {
      final amountOut = await repository.quoteExactInputSingle(
        tokenIn: effectiveTokenIn,
        tokenOut: effectiveTokenOut,
        amountIn: amountIn,
        fee: feeTier,
      );
      return (amountOut: amountOut, fee: feeTier);
    } catch (error) {
      if (_looksLikeNoPoolError(error)) {
        throw LiquidityPoolNotFoundException(tokenIn: tokenIn, tokenOut: tokenOut);
      }
      rethrow;
    }
  }

  bool _looksLikeNoPoolError(Object error) {
    final message = error.toString().toLowerCase();
    return (message.contains('pool') && message.contains('not')) ||
        message.contains('no liquidity') ||
        message.contains('liquidity pool');
  }
}
