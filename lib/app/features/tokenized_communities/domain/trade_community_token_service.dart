// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/models/community_token_buy_request.dart';

class TradeCommunityTokenService {
  TradeCommunityTokenService({
    required this.repository,
  });

  final TradeCommunityTokenRepository repository;

  Future<String> performBuy(CommunityTokenBuyRequest request) async {
    final fromTokenBytes = _hexToBytes(request.baseTokenAddress);
    final toTokenBytes = _encodeIdentifier(request.ionConnectAddress);

    final quote = await repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: request.amountIn,
    );

    final minReturn = _calculateMinReturn(
      expectedOut: quote,
      slippagePercent: request.slippagePercent,
    );

    final allowance = await repository.fetchAllowance(
      owner: request.walletAddress,
      tokenAddress: request.baseTokenAddress,
    );

    if (allowance < request.amountIn) {
      // Approve 1 Trillion tokens (10^12) with token decimals
      final trillionAmount = BigInt.from(10).pow(12 + request.tokenDecimals);

      await repository.approve(
        walletId: request.walletId,
        tokenAddress: request.baseTokenAddress,
        amount: trillionAmount,
        maxFeePerGas: request.maxFeePerGas,
        maxPriorityFeePerGas: request.maxPriorityFeePerGas,
        userActionSigner: request.userActionSigner,
      );
    }

    final txHash = await repository.buyCommunityToken(
      walletId: request.walletId,
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: request.amountIn,
      minReturn: minReturn,
      maxFeePerGas: request.maxFeePerGas,
      maxPriorityFeePerGas: request.maxPriorityFeePerGas,
      userActionSigner: request.userActionSigner,
    );

    return txHash;
  }

  Future<BigInt> getQuote({
    required String ionConnectAddress,
    required BigInt amountIn,
    required String baseTokenAddress,
  }) async {
    final fromTokenBytes = _hexToBytes(baseTokenAddress);
    final toTokenBytes = _encodeIdentifier(ionConnectAddress);

    return repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );
  }

  List<int> _encodeIdentifier(String identifier) {
    return utf8.encode(identifier);
  }

  BigInt _calculateMinReturn({
    required BigInt expectedOut,
    required double slippagePercent,
  }) {
    final normalized = slippagePercent.clamp(0, 100);
    const scale = 10000; // basis points precision
    final slippageBps = (normalized * 100).round().clamp(0, scale);
    final multiplier = scale - slippageBps;
    return (expectedOut * BigInt.from(multiplier)) ~/ BigInt.from(scale);
  }

  List<int> _hexToBytes(String hex) {
    var hexStr = hex;
    if (hexStr.startsWith('0x')) {
      hexStr = hexStr.substring(2);
    }
    if (hexStr.length % 2 != 0) {
      hexStr = '0$hexStr';
    }
    final result = <int>[];
    for (var i = 0; i < hexStr.length; i += 2) {
      final byte = int.parse(hexStr.substring(i, i + 2), radix: 16);
      result.add(byte);
    }
    return result;
  }
}
