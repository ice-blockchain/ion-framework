// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/transaction_amount.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_ion_connect_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/services/token_operation_protected_accounts_service.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

typedef TransactionResult = Map<String, dynamic>;

class TradeCommunityTokenService {
  TradeCommunityTokenService({
    required this.repository,
    required this.ionConnectService,
    required this.protectedAccountsService,
  });

  final TradeCommunityTokenRepository repository;
  final CommunityTokenIonConnectService ionConnectService;
  final TokenOperationProtectedAccountsService protectedAccountsService;

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
    required PricingResponse expectedPricing,
    required bool shouldSendEvents,
    FatAddressV2Data? fatAddressData,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
  }) async {
    // Check if this account is protected from token operations
    if (protectedAccountsService.isProtectedAccountFromExternalAddress(externalAddress)) {
      throw const TokenOperationProtectedException();
    }

    final tokenInfo = await repository.fetchTokenInfoFresh(externalAddress);
    final existingTokenAddress = _extractTokenAddress(tokenInfo);
    final firstBuy = _isFirstBuy(existingTokenAddress);
    final hasUserPosition = _hasUserPosition(tokenInfo);
    final toTokenBytes = _buildBuyToTokenBytes(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      tokenAddress: existingTokenAddress,
      fatAddressData: fatAddressData,
    );

    final transaction = await _performSwap(
      externalAddress: externalAddress,
      fromTokenAddress: baseTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      pricing: expectedPricing,
      slippagePercent: slippagePercent,
      walletId: walletId,
      walletAddress: walletAddress,
      allowanceTokenAddress: baseTokenAddress,
      tokenDecimals: tokenDecimals,
      userActionSigner: userActionSigner,
    );

    if (_isBroadcasted(transaction)) {
      await Future.wait([
        if (firstBuy)
          // First-buy events are always sent, regardless of [shouldSendEvents].
          _sendFirstBuyEvents(externalAddress: externalAddress),
        if (shouldSendEvents)
          _trySendBuyEvents(
            externalAddress: externalAddress,
            firstBuy: firstBuy,
            hasUserPosition: hasUserPosition,
            transaction: transaction,
            pricing: expectedPricing,
            amountIn: amountIn,
            walletNetwork: walletNetwork,
            baseTokenTicker: baseTokenTicker,
            tokenDecimals: tokenDecimals,
            existingTokenAddress: existingTokenAddress,
            tokenInfo: tokenInfo,
          ),
      ]);
    }

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
    required PricingResponse expectedPricing,
    required bool shouldSendEvents,
    double slippagePercent = TokenizedCommunitiesConstants.defaultSlippagePercent,
  }) async {
    // Check if this account is protected from token operations
    if (protectedAccountsService.isProtectedAccountFromExternalAddress(externalAddress)) {
      throw const TokenOperationProtectedException();
    }

    final tokenInfo = await repository.fetchTokenInfo(externalAddress);
    final toTokenBytes = _getBytesFromAddress(paymentTokenAddress);

    final transaction = await _performSwap(
      externalAddress: externalAddress,
      fromTokenAddress: communityTokenAddress,
      toTokenBytes: toTokenBytes,
      amountIn: amountIn,
      pricing: expectedPricing,
      slippagePercent: slippagePercent,
      walletId: walletId,
      walletAddress: walletAddress,
      allowanceTokenAddress: communityTokenAddress,
      tokenDecimals: tokenDecimals,
      userActionSigner: userActionSigner,
    );

    if (shouldSendEvents && _isBroadcasted(transaction)) {
      await _trySendSellEvents(
        externalAddress: externalAddress,
        transaction: transaction,
        pricing: expectedPricing,
        amountIn: amountIn,
        walletNetwork: walletNetwork,
        communityTokenAddress: communityTokenAddress,
        paymentTokenTicker: paymentTokenTicker,
        paymentTokenDecimals: paymentTokenDecimals,
        tokenInfo: tokenInfo,
      );
    }

    return transaction;
  }

  Future<PricingResponse> getQuote({
    required String pricingIdentifier,
    required CommunityTokenTradeMode mode,
    required String amount,
  }) async {
    return repository.fetchPricing(
      pricingIdentifier: pricingIdentifier,
      mode: mode,
      amount: amount,
    );
  }

  Future<CommunityToken?> fetchTokenInfoFresh(String externalAddress) async {
    return repository.fetchTokenInfoFresh(externalAddress);
  }

  Future<TransactionResult> _performSwap({
    required String externalAddress,
    required String fromTokenAddress,
    required List<int> toTokenBytes,
    required BigInt amountIn,
    required PricingResponse pricing,
    required double slippagePercent,
    required String walletId,
    required String walletAddress,
    required String allowanceTokenAddress,
    required int tokenDecimals,
    required UserActionSignerNew userActionSigner,
  }) async {
    final fromTokenBytes = _getBytesFromAddress(fromTokenAddress);

    final quote = BigInt.parse(pricing.amount);

    final minReturn = _calculateMinReturn(
      expectedOut: quote,
      slippagePercent: slippagePercent,
    );

    final approvalOperation = await _buildAllowanceApprovalOperationIfNeeded(
      owner: walletAddress,
      tokenAddress: allowanceTokenAddress,
      requiredAmount: amountIn,
      tokenDecimals: tokenDecimals,
    );

    final swapOperation = await repository.buildSwapUserOperation(
      fromTokenIdentifier: fromTokenBytes,
      toTokenIdentifier: toTokenBytes,
      amountIn: amountIn,
      minReturn: minReturn,
    );

    final userOperations = <EvmUserOperation>[
      if (approvalOperation != null) approvalOperation,
      swapOperation,
    ];

    return repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOperations,
      feeSponsorId: TokenizedCommunitiesConstants.tradeFeeSponsorWalletId,
      userActionSigner: userActionSigner,
    );
  }

  Future<void> _sendFirstBuyEvents({
    required String externalAddress,
  }) async {
    return ionConnectService.sendFirstBuyEvents(externalAddress: externalAddress);
  }

  Future<void> _trySendBuyEvents({
    required String externalAddress,
    required bool firstBuy,
    required bool hasUserPosition,
    required TransactionResult transaction,
    required PricingResponse pricing,
    required BigInt amountIn,
    required String walletNetwork,
    required String baseTokenTicker,
    required int tokenDecimals,
    required String? existingTokenAddress,
    required CommunityToken? tokenInfo,
  }) async {
    try {
      final txHash = transaction['txHash'] as String?;
      if (txHash == null || txHash.isEmpty) {
        throw TransactionHashNotFoundException(externalAddress);
      }

      final bondingCurveAddress = await repository.fetchBondingCurveAddress();

      // First buy can create token contract, analytics may lag behind.
      // Retry fetching token address until it's available.
      final tokenAddress = existingTokenAddress ??
          await withRetry<String>(
            ({Object? error}) async {
              final tokenAddress =
                  _extractTokenAddress(await repository.fetchTokenInfoFresh(externalAddress));
              if (tokenAddress == null || tokenAddress.isEmpty) {
                throw TokenAddressNotFoundException(externalAddress);
              }
              return tokenAddress;
            },
            retryWhen: (error) => error is TokenAddressNotFoundException,
          );

      const communityTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;

      final baseTokenAmountValue = fromBlockchainUnits(amountIn.toString(), tokenDecimals);

      final communityTokenAmountValue = fromBlockchainUnits(pricing.amount, communityTokenDecimals);

      final usdAmountValue = pricing.amountUSD;

      final amountBase = TransactionAmount(
        value: baseTokenAmountValue,
        currency: baseTokenTicker,
      );
      final amountQuote = TransactionAmount(
        value: communityTokenAmountValue,
        currency: externalAddress,
      );
      final amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

      await ionConnectService.sendBuyActionEvents(
        externalAddress: externalAddress,
        network: walletNetwork,
        hasUserPosition: hasUserPosition,
        bondingCurveAddress: bondingCurveAddress,
        tokenAddress: tokenAddress,
        transactionAddress: txHash,
        amountBase: amountBase,
        amountQuote: amountQuote,
        amountUsd: amountUsd,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to send buy events for $externalAddress',
      );
      unawaited(SentryService.logException(error, stackTrace: stackTrace));
    }
  }

  Future<void> _trySendSellEvents({
    required String externalAddress,
    required TransactionResult transaction,
    required PricingResponse pricing,
    required BigInt amountIn,
    required String walletNetwork,
    required String communityTokenAddress,
    required String paymentTokenTicker,
    required int paymentTokenDecimals,
    required CommunityToken? tokenInfo,
  }) async {
    try {
      final txHash = transaction['txHash'] as String?;
      if (txHash == null || txHash.isEmpty) {
        throw TransactionHashNotFoundException(externalAddress);
      }

      final bondingCurveAddress = await repository.fetchBondingCurveAddress();
      const communityTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;

      final communityTokenAmountValue =
          fromBlockchainUnits(amountIn.toString(), communityTokenDecimals);
      final paymentTokenAmountValue = fromBlockchainUnits(pricing.amount, paymentTokenDecimals);

      final usdAmountValue = pricing.amountUSD;

      final amountBase =
          TransactionAmount(value: communityTokenAmountValue, currency: externalAddress);
      final amountQuote = TransactionAmount(
        value: paymentTokenAmountValue,
        currency: paymentTokenTicker,
      );
      final amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

      await ionConnectService.sendSellActionEvents(
        externalAddress: externalAddress,
        network: walletNetwork,
        bondingCurveAddress: bondingCurveAddress,
        tokenAddress: communityTokenAddress,
        transactionAddress: txHash,
        amountBase: amountBase,
        amountQuote: amountQuote,
        amountUsd: amountUsd,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to send sell events for $externalAddress',
      );
      unawaited(SentryService.logException(error, stackTrace: stackTrace));
    }
  }

  bool _isBroadcasted(TransactionResult transaction) {
    final status = transaction['status']?.toString() ?? '';
    return status.toLowerCase() == 'broadcasted';
  }

  bool _hasUserPosition(CommunityToken? tokenInfo) => tokenInfo?.marketData.position != null;

  bool _isFirstBuy(String? tokenAddress) => tokenAddress == null || tokenAddress.isEmpty;

  String? _extractTokenAddress(CommunityToken? tokenInfo) => tokenInfo?.addresses.blockchain;

  List<int> _buildBuyToTokenBytes({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? tokenAddress,
    required FatAddressV2Data? fatAddressData,
  }) {
    if (tokenAddress != null && tokenAddress.isNotEmpty) {
      return _getBytesFromAddress(tokenAddress);
    }
    if (fatAddressData == null) {
      throw StateError('fatAddressData is required for first buy of $externalAddress');
    }
    return fatAddressData.toBytes();
  }

  Future<EvmUserOperation?> _buildAllowanceApprovalOperationIfNeeded({
    required String owner,
    required String tokenAddress,
    required BigInt requiredAmount,
    required int tokenDecimals,
  }) async {
    final allowance = await repository.fetchAllowance(
      owner: owner,
      tokenAddress: tokenAddress,
    );

    if (allowance >= requiredAmount) return null;

    final approvalAmount = BigInt.from(10).pow(
      TokenizedCommunitiesConstants.approvalTrillionMultiplier + tokenDecimals,
    );

    return repository.buildApproveUserOperation(
      tokenAddress: tokenAddress,
      amount: approvalAmount,
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
}
