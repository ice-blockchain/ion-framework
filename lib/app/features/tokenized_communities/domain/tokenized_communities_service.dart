// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/tokenized_communities/domain/tokenized_communities_repository.dart';
import 'package:ion/app/features/tokenized_communities/models/creator_token_buy_request.dart';

class TokenizedCommunitiesService {
  TokenizedCommunitiesService({
    required this.repository,
  });

  final TokenizedCommunitiesRepository repository;

  Future<String> performBuy(CreatorTokenBuyRequest request) async {
    final fromTokenBytes = _hexToBytes(request.baseTokenAddress);
    final toTokenBytes = _encodeIdentifier(
      _ionConnectAddress(request.creatorPubkey),
    );

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

    final txHash = await repository.buyCreatorToken(
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

  List<int> _encodeIdentifier(String identifier) {
    return utf8.encode(identifier);
  }

  String _ionConnectAddress(String creatorPubkey) {
    return '0:$creatorPubkey:';
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
