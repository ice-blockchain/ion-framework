// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_community_token_repository.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_quote_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_route_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/trade_user_ops_builder.dart';
import 'package:ion/app/features/tokenized_communities/domain/transaction_result.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/transaction_amount.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_ion_connect_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/services/token_operation_protected_accounts_service.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeCommunityTokenService {
  TradeCommunityTokenService({
    required this.repository,
    required this.ionConnectService,
    required this.protectedAccountsService,
    required this.routeBuilder,
    required this.quoteBuilder,
    required this.userOpsBuilder,
  });

  final TradeCommunityTokenRepository repository;
  final CommunityTokenIonConnectService ionConnectService;
  final TokenOperationProtectedAccountsService protectedAccountsService;
  final TradeRouteBuilder routeBuilder;
  final TradeQuoteBuilder quoteBuilder;
  final TradeUserOpsBuilder userOpsBuilder;

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
    _ensureAccountNotProtected(externalAddress);
    final tokenInfo = await repository.fetchTokenInfoFresh(externalAddress);
    final existingTokenAddress = _extractTokenAddress(tokenInfo);
    final firstBuy = _isFirstBuy(existingTokenAddress);
    final hasUserPosition = _hasUserPosition(tokenInfo);
    final isCreatorTokenMissingForContentFirstBuy = _isCreatorTokenMissingForContentFirstBuy(
      externalAddressType: externalAddressType,
      isFirstBuy: firstBuy,
      fatAddressData: fatAddressData,
    );

    final pricingIdentifier = _resolveBuyPricingIdentifier(
      externalAddress: externalAddress,
      tokenInfo: tokenInfo,
      fatAddressData: fatAddressData,
    );
    final paymentRoleOverride = await _resolvePaymentTokenRoleOverride(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      paymentTokenAddress: baseTokenAddress,
    );
    final route = routeBuilder.build(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: CommunityTokenTradeMode.buy,
      paymentTokenAddress: baseTokenAddress,
      paymentTokenRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
    );
    final quote = await quoteBuilder.build(
      route: route,
      pricingIdentifier: pricingIdentifier,
      amountIn: amountIn,
      paymentTokenAddress: baseTokenAddress,
      slippagePercent: slippagePercent,
      fatAddressHex: fatAddressData?.toHex(),
    );
    final userOps = await userOpsBuilder.buildUserOps(
      route: route,
      quote: quote,
      walletAddress: walletAddress,
      paymentTokenAddress: baseTokenAddress,
      paymentTokenDecimals: tokenDecimals,
      communityTokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
      fatAddressData: fatAddressData,
    );
    final transaction = await repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOps,
      feeSponsorId: TokenizedCommunitiesConstants.tradeFeeSponsorWalletId,
      userActionSigner: userActionSigner,
    );

    if (_isBroadcasted(transaction)) {
      final masterPubkey = MasterPubkeyResolver.resolve(externalAddress);

      final profileEventReference =
          ReplaceableEventReference(masterPubkey: masterPubkey, kind: UserMetadataEntity.kind);

      final hasProfileToken =
          await ionConnectService.ionConnectEntityHasToken(profileEventReference);
      await Future.wait([
        if (firstBuy)
          // First-buy events are always sent, regardless of [shouldSendEvents].
          _sendFirstBuyEvents(externalAddress: externalAddress),
        if (externalAddressType.isContentToken && firstBuy && !hasProfileToken)
          _sendFirstBuyEvents(externalAddress: profileEventReference.toString()),
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
    required ExternalAddressType externalAddressType,
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
    _ensureAccountNotProtected(externalAddress);
    final paymentRoleOverride = await _resolvePaymentTokenRoleOverride(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      paymentTokenAddress: paymentTokenAddress,
    );
    final route = routeBuilder.build(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: CommunityTokenTradeMode.sell,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenRoleOverride: paymentRoleOverride,
    );

    final tokenInfo = await repository.fetchTokenInfo(externalAddress);

    final quote = await quoteBuilder.build(
      route: route,
      pricingIdentifier: externalAddress,
      amountIn: amountIn,
      paymentTokenAddress: paymentTokenAddress,
      slippagePercent: slippagePercent,
    );
    final userOps = await userOpsBuilder.buildUserOps(
      route: route,
      quote: quote,
      walletAddress: walletAddress,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenDecimals: paymentTokenDecimals,
      communityTokenDecimals: tokenDecimals,
      communityTokenAddress: communityTokenAddress,
    );
    final transaction = await repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOps,
      feeSponsorId: TokenizedCommunitiesConstants.tradeFeeSponsorWalletId,
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
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String pricingIdentifier,
    required CommunityTokenTradeMode mode,
    required String amount,
    required String paymentTokenAddress,
    FatAddressV2Data? fatAddressData,
  }) async {
    final paymentRoleOverride = await _resolvePaymentTokenRoleOverride(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      paymentTokenAddress: paymentTokenAddress,
    );
    final isCreatorTokenMissingForContentFirstBuy = _isCreatorTokenMissingForContentFirstBuy(
      externalAddressType: externalAddressType,
      isFirstBuy: mode == CommunityTokenTradeMode.buy && fatAddressData != null,
      fatAddressData: fatAddressData,
    );
    final route = routeBuilder.build(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: mode,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
    );
    final quote = await quoteBuilder.build(
      route: route,
      pricingIdentifier: pricingIdentifier,
      amountIn: BigInt.parse(amount),
      paymentTokenAddress: paymentTokenAddress,
      slippagePercent: 0,
      fatAddressHex: _looksLikeHex(pricingIdentifier) ? pricingIdentifier : null,
    );
    return quote.finalPricing;
  }

  Future<CommunityToken?> fetchTokenInfoFresh(String externalAddress) async {
    return repository.fetchTokenInfoFresh(externalAddress);
  }

  Future<TransactionResult> updateTokenMetadata({
    required String externalAddress,
    required String walletId,
    required String walletAddress,
    required UserActionSignerNew userActionSigner,
    required String newName,
    required String newSymbol,
  }) async {
    final tokenInfo = await repository.fetchTokenInfoFresh(externalAddress);
    final tokenAddress = _extractTokenAddress(tokenInfo);
    if (tokenAddress == null || tokenAddress.isEmpty) {
      return {'status': 'skipped'};
    }

    final metadataOwner = await repository.fetchTokenMetadataOwner(tokenAddress);
    if (!_sameAddress(metadataOwner, walletAddress)) {
      return {'status': 'skipped'};
    }

    final currentName = await repository.fetchTokenName(tokenAddress);
    final currentSymbol = await repository.fetchTokenSymbol(tokenAddress);
    if (currentName == newName && currentSymbol == newSymbol) {
      return {'status': 'skipped'};
    }

    final updateOperation = await repository.buildUpdateMetadataUserOperation(
      tokenAddress: tokenAddress,
      newName: newName,
      newSymbol: newSymbol,
    );

    final result = await repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: [updateOperation],
      feeSponsorId: TokenizedCommunitiesConstants.tradeFeeSponsorWalletId,
      userActionSigner: userActionSigner,
    );
    return result;
  }

  void _ensureAccountNotProtected(String externalAddress) {
    if (protectedAccountsService.isProtectedAccountFromExternalAddress(externalAddress)) {
      throw const TokenOperationProtectedException();
    }
  }

  String _resolveBuyPricingIdentifier({
    required String externalAddress,
    required CommunityToken? tokenInfo,
    FatAddressV2Data? fatAddressData,
  }) {
    final tokenAddress = tokenInfo?.addresses.blockchain?.trim() ?? '';
    if (tokenAddress.isNotEmpty) {
      return externalAddress;
    }
    final fatHex = fatAddressData?.toHex() ?? '';
    if (fatHex.isNotEmpty) {
      return fatHex;
    }
    throw StateError('fatAddressData is required for first buy of $externalAddress');
  }

  Future<TradeTokenRole?> _resolvePaymentTokenRoleOverride({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String paymentTokenAddress,
  }) async {
    if (!externalAddressType.isContentToken) {
      return null;
    }
    final creatorExternalAddress =
        MasterPubkeyResolver.creatorExternalAddressFromExternal(externalAddress);
    final creatorTokenInfo = await repository.fetchTokenInfo(creatorExternalAddress);
    final creatorTokenAddress = creatorTokenInfo?.addresses.blockchain?.trim() ?? '';
    if (creatorTokenAddress.isEmpty) {
      return null;
    }
    if (_sameAddress(creatorTokenAddress, paymentTokenAddress)) {
      return TradeTokenRole.creator;
    }
    return null;
  }

  bool _isCreatorTokenMissingForContentFirstBuy({
    required ExternalAddressType externalAddressType,
    required bool isFirstBuy,
    required FatAddressV2Data? fatAddressData,
  }) {
    if (!externalAddressType.isContentToken || !isFirstBuy) {
      return false;
    }
    if (fatAddressData == null) {
      return false;
    }
    final creatorExternalType = _creatorExternalTypeByte();
    return fatAddressData.tokens.any(
      (token) => token.externalType == creatorExternalType,
    );
  }

  int _creatorExternalTypeByte() {
    final prefix = const ExternalAddressType.ionConnectUser().prefix;
    if (prefix.length != 1) {
      throw StateError('Creator external type prefix must be 1 character.');
    }
    return prefix.codeUnitAt(0);
  }

  bool _looksLikeHex(String value) {
    final normalized = value.trim();
    if (!normalized.startsWith('0x')) return false;
    if (normalized.length < 4) return false;
    return true;
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

  bool _sameAddress(String? left, String? right) {
    if (left == null || right == null) return false;
    return left.toLowerCase() == right.toLowerCase();
  }

  String? _extractTokenAddress(CommunityToken? tokenInfo) => tokenInfo?.addresses.blockchain;
}
