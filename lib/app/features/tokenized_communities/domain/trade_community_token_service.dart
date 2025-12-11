// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion_identity_client/ion_identity.dart';

class TradeCommunityTokenService {
  TradeCommunityTokenService({
    required this.repository,
  });

  final TradeCommunityTokenRepository repository;

  Future<String> buyCommunityToken({
    required String externalAddress,
    required BigInt amountIn,
    required String walletId,
    required String walletAddress,
    required String baseTokenAddress,
    required int tokenDecimals,
    required UserActionSignerNew userActionSigner,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) async {
    final toTokenBytes = await _resolveTokenBytes(externalAddress);

    return _performSwap(
      fromTokenAddress: baseTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      slippagePercent: slippagePercent,
      walletId: walletId,
      walletAddress: walletAddress,
      allowanceTokenAddress: baseTokenAddress,
      tokenDecimals: tokenDecimals,
      maxFeePerGas: maxFeePerGas ?? TokenizedCommunitiesConstants.defaultMaxFeePerGas,
      maxPriorityFeePerGas:
          maxPriorityFeePerGas ?? TokenizedCommunitiesConstants.defaultMaxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );
  }

  Future<String> sellCommunityToken({
    required String externalAddress,
    required BigInt amountIn,
    required String walletId,
    required String walletAddress,
    required String paymentTokenAddress,
    required String communityTokenAddress,
    required int tokenDecimals,
    required UserActionSignerNew userActionSigner,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) async {
    final toTokenBytes = _getBytesFromAddress(paymentTokenAddress);

    return _performSwap(
      fromTokenAddress: communityTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      slippagePercent: slippagePercent,
      walletId: walletId,
      walletAddress: walletAddress,
      allowanceTokenAddress: communityTokenAddress,
      tokenDecimals: tokenDecimals,
      maxFeePerGas: maxFeePerGas ?? TokenizedCommunitiesConstants.defaultMaxFeePerGas,
      maxPriorityFeePerGas:
          maxPriorityFeePerGas ?? TokenizedCommunitiesConstants.defaultMaxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );
  }

  Future<BigInt> getQuote({
    required String externalAddress,
    required BigInt amountIn,
    required String baseTokenAddress,
  }) async {
    final fromTokenBytes = _getBytesFromAddress(baseTokenAddress);
    final toTokenBytes = await _resolveTokenBytes(externalAddress);

    return repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );
  }

  Future<BigInt> getSellQuote({
    required String externalAddress,
    required BigInt amountIn,
    required String paymentTokenAddress,
  }) async {
    final fromTokenBytes = await _resolveTokenBytes(externalAddress);
    final toTokenBytes = _getBytesFromAddress(paymentTokenAddress);

    return repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );
  }

  /// Resolves token identifier to bytes.
  /// Returns contract address bytes if token exists, otherwise returns FatAddress bytes.
  Future<List<int>> _resolveTokenBytes(String externalAddress) async {
    final contractAddress = await repository.fetchContractAddress(externalAddress);

    if (contractAddress != null) {
      // Token already exists, use contract address bytes
      return _getBytesFromAddress(contractAddress);
    }

    // First purchase: build FatAddress (creatorTokenAddress + externalAddress)
    return _buildFatAddress(externalAddress);
  }

  Future<String> _performSwap({
    required String fromTokenAddress,
    required List<int> toTokenBytes,
    required BigInt amountIn,
    required double slippagePercent,
    required String walletId,
    required String walletAddress,
    required String allowanceTokenAddress,
    required int tokenDecimals,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
    required UserActionSignerNew userActionSigner,
  }) async {
    final fromTokenBytes = _getBytesFromAddress(fromTokenAddress);

    final quote = await repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );

    final minReturn = _calculateMinReturn(
      expectedOut: quote,
      slippagePercent: slippagePercent,
    );

    await _ensureAllowance(
      owner: walletAddress,
      tokenAddress: allowanceTokenAddress,
      requiredAmount: amountIn,
      walletId: walletId,
      tokenDecimals: tokenDecimals,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );

    return repository.swapCommunityToken(
      walletId: walletId,
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
      minReturn: minReturn,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );
  }

  Future<void> _ensureAllowance({
    required String owner,
    required String tokenAddress,
    required BigInt requiredAmount,
    required String walletId,
    required int tokenDecimals,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
    required UserActionSignerNew userActionSigner,
  }) async {
    final allowance = await repository.fetchAllowance(
      owner: owner,
      tokenAddress: tokenAddress,
    );

    if (allowance >= requiredAmount) return;

    final approvalAmount = BigInt.from(10).pow(
      TokenizedCommunitiesConstants.approvalTrillionMultiplier + tokenDecimals,
    );

    await repository.approve(
      walletId: walletId,
      tokenAddress: tokenAddress,
      amount: approvalAmount,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );
  }

  List<int> _encodeIdentifier(String identifier) {
    return utf8.encode(identifier);
  }

  BigInt _calculateMinReturn({
    required BigInt expectedOut,
    required double slippagePercent,
  }) {
    final normalized = slippagePercent.clamp(
      0,
      TokenizedCommunitiesConstants.maxSlippagePercent,
    );
    final slippageBps = (normalized * TokenizedCommunitiesConstants.percentToBasisPointsMultiplier)
        .round()
        .clamp(0, TokenizedCommunitiesConstants.basisPointsScale);
    final multiplier = TokenizedCommunitiesConstants.basisPointsScale - slippageBps;
    return (expectedOut * BigInt.from(multiplier)) ~/
        BigInt.from(TokenizedCommunitiesConstants.basisPointsScale);
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

  List<int> _getBytesFromAddress(String address) {
    if (address.startsWith('0x')) {
      return _hexToBytes(address);
    }
    return _encodeIdentifier(address);
  }

  /// Builds FatAddress for first-time token purchase.
  /// FatAddress format: creatorTokenAddress (20 bytes) + externalAddress bytes
  /// For Twitter (z/y/x/w) and creatorToken (a): creatorTokenAddress = 20 zero bytes
  /// For contentToken (b/c/d): creatorTokenAddress should be the creator's token address
  List<int> _buildFatAddress(String externalAddress) {
    final creatorTokenAddressBytes = List<int>.filled(20, 0);

    final externalAddressBytes = _encodeIdentifier(externalAddress);

    return [...creatorTokenAddressBytes, ...externalAddressBytes];
  }
}
