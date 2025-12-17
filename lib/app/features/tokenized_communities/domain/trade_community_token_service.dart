// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/transaction_amount.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_ion_connect_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

typedef TransactionResult = Map<String, dynamic>;

class TradeCommunityTokenService {
  TradeCommunityTokenService({
    required this.repository,
    required this.ionConnectService,
  });

  final TradeCommunityTokenRepository repository;
  final CommunityTokenIonConnectService ionConnectService;

  Future<TransactionResult> buyCommunityToken({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required BigInt amountIn,
    required String walletId,
    required String walletAddress,
    required String walletNetwork,
    required String baseTokenAddress,
    required String baseTokenTicker,
    required int tokenDecimals,
    required UserActionSignerNew userActionSigner,
    BigInt? expectedOutQuote,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) async {
    final tokenInfo = await repository.fetchTokenInfo(externalAddress);
    final existingTokenAddress = _extractTokenAddress(tokenInfo);
    final firstBuy = _isFirstBuy(existingTokenAddress);
    final toTokenBytes = _buildBuyToTokenBytes(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      tokenAddress: existingTokenAddress,
    );

    final (:transaction, :quote) = await _performSwap(
      fromTokenAddress: baseTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      expectedOutQuote: expectedOutQuote,
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

    await _trySendBuyEvents(
      externalAddress: externalAddress,
      firstBuy: firstBuy,
      transaction: transaction,
      quote: quote,
      amountIn: amountIn,
      walletNetwork: walletNetwork,
      baseTokenTicker: baseTokenTicker,
      tokenDecimals: tokenDecimals,
      existingTokenAddress: existingTokenAddress,
      tokenInfo: tokenInfo,
    );

    return transaction;
  }

  Future<TransactionResult> sellCommunityToken({
    required String externalAddress,
    required BigInt amountIn,
    required String walletId,
    required String walletAddress,
    required String walletNetwork,
    required String paymentTokenAddress,
    required String paymentTokenTicker,
    required int paymentTokenDecimals,
    required String communityTokenAddress,
    required int tokenDecimals,
    required UserActionSignerNew userActionSigner,
    BigInt? expectedOutQuote,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
    BigInt? maxFeePerGas,
    BigInt? maxPriorityFeePerGas,
  }) async {
    final tokenInfo = await repository.fetchTokenInfo(externalAddress);
    final toTokenBytes = _getBytesFromAddress(paymentTokenAddress);

    final (:transaction, :quote) = await _performSwap(
      fromTokenAddress: communityTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      expectedOutQuote: expectedOutQuote,
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

    await _trySendSellEvents(
      externalAddress: externalAddress,
      transaction: transaction,
      quote: quote,
      amountIn: amountIn,
      walletNetwork: walletNetwork,
      communityTokenAddress: communityTokenAddress,
      paymentTokenTicker: paymentTokenTicker,
      paymentTokenDecimals: paymentTokenDecimals,
      tokenInfo: tokenInfo,
    );

    return transaction;
  }

  Future<BigInt> getQuote({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required BigInt amountIn,
    required String baseTokenAddress,
  }) async {
    final fromTokenBytes = _getBytesFromAddress(baseTokenAddress);
    final toTokenBytes = await _resolveTokenBytes(externalAddress, externalAddressType);

    return repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );
  }

  Future<BigInt> getSellQuote({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required BigInt amountIn,
    required String paymentTokenAddress,
  }) async {
    final fromTokenBytes = await _resolveTokenBytes(externalAddress, externalAddressType);
    final toTokenBytes = _getBytesFromAddress(paymentTokenAddress);

    return repository.fetchQuote(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
    );
  }

  /// Resolves token identifier to bytes.
  /// Returns contract address bytes if token exists, otherwise returns FatAddress bytes.
  Future<List<int>> _resolveTokenBytes(
    String externalAddress,
    ExternalAddressType externalAddressType,
  ) async {
    final tokenInfo = await repository.fetchTokenInfo(externalAddress);
    final tokenAddress = tokenInfo?.addresses.blockchain;
    if (tokenAddress != null) {
      return _getBytesFromAddress(tokenAddress);
    }

    return _buildFatAddress(externalAddress, externalAddressType);
  }

  Future<({TransactionResult transaction, BigInt quote})> _performSwap({
    required String fromTokenAddress,
    required List<int> toTokenBytes,
    required BigInt amountIn,
    required BigInt? expectedOutQuote,
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

    final quote = expectedOutQuote ??
        await repository.fetchQuote(
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

    final transaction = await repository.swapCommunityToken(
      walletId: walletId,
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
      minReturn: minReturn,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
      userActionSigner: userActionSigner,
    );
    return (transaction: transaction, quote: quote);
  }

  Future<void> _trySendBuyEvents({
    required String externalAddress,
    required bool firstBuy,
    required TransactionResult transaction,
    required BigInt quote,
    required BigInt amountIn,
    required String walletNetwork,
    required String baseTokenTicker,
    required int tokenDecimals,
    required String? existingTokenAddress,
    required CommunityToken? tokenInfo,
  }) async {
    if (!_isBroadcasted(transaction)) return;

    final txHash = transaction['txHash'] as String?;
    if (txHash == null || txHash.isEmpty) return;

    final bondingCurveAddress = await repository.fetchBondingCurveAddress();
    var tokenAddress = existingTokenAddress ?? _extractTokenAddress(tokenInfo);
    if (tokenAddress == null && firstBuy) {
      // First buy can create token contract, analytics may lag behind.
      // Retry once to avoid excessive requests.
      tokenAddress = _extractTokenAddress(await repository.fetchTokenInfo(externalAddress));
    }
    if (tokenAddress == null || tokenAddress.isEmpty) return;

    final communityTokenTicker = tokenInfo?.title ?? externalAddress;
    const communityTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;

    final baseTokenAmountValue = fromBlockchainUnits(amountIn.toString(), tokenDecimals);

    final communityTokenAmountValue = fromBlockchainUnits(quote.toString(), communityTokenDecimals);

    // TODO(ion): Replace with PricingResponse.amountUSD from pricing API.
    const usdAmountValue = 1.0;

    final amountBase = TransactionAmount(value: baseTokenAmountValue, currency: baseTokenTicker);
    final amountQuote =
        TransactionAmount(value: communityTokenAmountValue, currency: communityTokenTicker);
    const amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

    try {
      await ionConnectService.sendBuyEvents(
        externalAddress: externalAddress,
        firstBuy: firstBuy,
        network: walletNetwork,
        bondingCurveAddress: bondingCurveAddress,
        tokenAddress: tokenAddress,
        transactionAddress: txHash,
        amountBase: amountBase,
        amountQuote: amountQuote,
        amountUsd: amountUsd,
      );
    } on Exception catch (e, stackTrace) {
      Logger.error('Failed to send buy events: $e', stackTrace: stackTrace);
    }
  }

  Future<void> _trySendSellEvents({
    required String externalAddress,
    required TransactionResult transaction,
    required BigInt quote,
    required BigInt amountIn,
    required String walletNetwork,
    required String communityTokenAddress,
    required String paymentTokenTicker,
    required int paymentTokenDecimals,
    required CommunityToken? tokenInfo,
  }) async {
    if (!_isBroadcasted(transaction)) return;

    final txHash = transaction['txHash'] as String?;
    if (txHash == null || txHash.isEmpty) return;

    final bondingCurveAddress = await repository.fetchBondingCurveAddress();
    final communityTokenTicker = tokenInfo?.title ?? externalAddress;
    const communityTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;

    final communityTokenAmountValue =
        fromBlockchainUnits(amountIn.toString(), communityTokenDecimals);
    final paymentTokenAmountValue = fromBlockchainUnits(quote.toString(), paymentTokenDecimals);

    // TODO(ion): Replace with PricingResponse.amountUSD from pricing API.
    const usdAmountValue = 1.0;

    final amountBase =
        TransactionAmount(value: communityTokenAmountValue, currency: communityTokenTicker);
    final amountQuote =
        TransactionAmount(value: paymentTokenAmountValue, currency: paymentTokenTicker);
    const amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

    try {
      await ionConnectService.sendSellEvents(
        externalAddress: externalAddress,
        network: walletNetwork,
        bondingCurveAddress: bondingCurveAddress,
        tokenAddress: communityTokenAddress,
        transactionAddress: txHash,
        amountBase: amountBase,
        amountQuote: amountQuote,
        amountUsd: amountUsd,
      );
    } on Exception catch (e, stackTrace) {
      Logger.error('Failed to send sell events: $e', stackTrace: stackTrace);
    }
  }

  bool _isBroadcasted(TransactionResult transaction) {
    final status = transaction['status']?.toString() ?? '';
    return status.toLowerCase() == 'broadcasted';
  }

  bool _isFirstBuy(String? tokenAddress) => tokenAddress == null || tokenAddress.isEmpty;

  String? _extractTokenAddress(CommunityToken? tokenInfo) => tokenInfo?.addresses.blockchain;

  List<int> _buildBuyToTokenBytes({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? tokenAddress,
  }) {
    if (tokenAddress != null && tokenAddress.isNotEmpty) {
      return _getBytesFromAddress(tokenAddress);
    }
    return _buildFatAddress(externalAddress, externalAddressType);
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
  List<int> _buildFatAddress(String externalAddress, ExternalAddressType externalAddressType) {
    final creatorTokenAddressBytes = List<int>.filled(20, 0);

    final fullExternalAddress = '${externalAddressType.prefix}$externalAddress';
    final externalAddressBytes = _encodeIdentifier(fullExternalAddress);

    return [...creatorTokenAddressBytes, ...externalAddressBytes];
  }
}
