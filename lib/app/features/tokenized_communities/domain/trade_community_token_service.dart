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
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/utils/crypto.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

//TODO cleanup extensive logs after swap becomes stable
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
    Logger.info(
      '[TradeCommunityTokenService] buyCommunityToken called | externalAddress=$externalAddress | externalAddressType=$externalAddressType',
    );
    _ensureAccountNotProtected(externalAddress);

    final tokenInfo = await repository.fetchTokenInfoFresh(externalAddress);

    Logger.info('[TradeCommunityTokenService] Fetched token info');
    final existingTokenAddress = _extractTokenAddress(tokenInfo);
    final firstBuy = await _isFirstBuy(externalAddress, externalAddressType);
    final hasUserPosition = _hasUserPosition(tokenInfo);
    Logger.info(
      '[TradeCommunityTokenService] Token info | existingTokenAddress=$existingTokenAddress | firstBuy=$firstBuy | hasUserPosition=$hasUserPosition',
    );

    final isCreatorTokenMissingForContentFirstBuy = _isCreatorTokenMissingForContentFirstBuy(
      externalAddressType: externalAddressType,
      isFirstBuy: firstBuy,
      fatAddressData: fatAddressData,
    );
    Logger.info(
      '[TradeCommunityTokenService] Resolving pricing identifier | externalAddress=$externalAddress | hasTokenAddress=${tokenInfo?.addresses.blockchain != null} | hasFatAddress=${fatAddressData != null}',
    );
    final pricingIdentifier = _resolveBuyPricingIdentifier(
      externalAddress: externalAddress,
      tokenInfo: tokenInfo,
      fatAddressData: fatAddressData,
    );
    Logger.info(
      '[TradeCommunityTokenService] Pricing identifier resolved | pricingIdentifier=$pricingIdentifier',
    );
    final paymentRoleOverride = await _resolvePaymentTokenRoleOverride(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      paymentTokenAddress: baseTokenAddress,
    );
    final routeQuote = await _buildRouteAndQuote(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: CommunityTokenTradeMode.buy,
      paymentTokenAddress: baseTokenAddress,
      paymentRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
      pricingIdentifier: pricingIdentifier,
      amountIn: amountIn,
      slippagePercent: slippagePercent,
      fatAddressHex: fatAddressData?.toHex(),
    );
    Logger.info(
      '[TradeCommunityTokenService] Building user operations | quoteAmount=${routeQuote.quote.finalPricing.amount} | quoteAmountUSD=${routeQuote.quote.finalPricing.amountUSD}',
    );
    final userOps = await userOpsBuilder.buildUserOps(
      route: routeQuote.route,
      quote: routeQuote.quote,
      walletAddress: walletAddress,
      paymentTokenAddress: baseTokenAddress,
      paymentTokenDecimals: tokenDecimals,
      communityTokenDecimals: TokenizedCommunitiesConstants.creatorTokenDecimals,
      fatAddressData: fatAddressData,
    );
    Logger.info('[TradeCommunityTokenService] Signing and broadcasting user operations');
    final transaction = await repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOps,
      feeSponsorId: routeQuote.quote.finalPricing.feeSponsorId,
      userActionSigner: userActionSigner,
    );

    Logger.info(
      '[TradeCommunityTokenService] Swap completed | status=${transaction['status']} | isBroadcasted=${_isBroadcasted(transaction)}',
    );

    if (_isBroadcasted(transaction)) {
      String? masterPubkey;
      ReplaceableEventReference? profileEventReference;
      var hasProfileToken = false;

      // We skip master pubkey resolution and profile-related events for non-content tokens to avoid parsing errors.
      if (externalAddressType.isContentToken) {
        Logger.info(
          '[TradeCommunityTokenService] Resolving master pubkey and checking profile token',
        );
        try {
          // Only resolve master pubkey for Ion Connect tokens (not external/X tokens)
          masterPubkey = MasterPubkeyResolver.resolve(externalAddress);
          profileEventReference =
              ReplaceableEventReference(masterPubkey: masterPubkey, kind: UserMetadataEntity.kind);
          hasProfileToken = await ionConnectService.ionConnectEntityHasToken(profileEventReference);
          Logger.info(
            '[TradeCommunityTokenService] Master pubkey resolved | masterPubkey=$masterPubkey | hasProfileToken=$hasProfileToken',
          );
        } catch (error, stackTrace) {
          Logger.error(
            error,
            stackTrace: stackTrace,
            message:
                '[TradeCommunityTokenService] Failed to resolve master pubkey or check profile token | externalAddress=$externalAddress',
          );
          // Continue without profile events if we can't resolve master pubkey
        }
      }

      Logger.info(
        '[TradeCommunityTokenService] Sending events | firstBuy=$firstBuy | shouldSendEvents=$shouldSendEvents | isContentToken=${externalAddressType.isContentToken}',
      );

      await Future.wait([
        if (firstBuy)
          // First-buy events are always sent, regardless of [shouldSendEvents].
          _sendFirstBuyEvents(externalAddress: externalAddress),
        if (externalAddressType.isContentToken && !hasProfileToken && profileEventReference != null)
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

    Logger.info('[TradeCommunityTokenService] buyCommunityToken completed successfully');
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
    Logger.info(
      '[TradeCommunityTokenService] sellCommunityToken called | externalAddress=$externalAddress | externalAddressType=$externalAddressType',
    );
    _ensureAccountNotProtected(externalAddress);
    final paymentRoleOverride = await _resolvePaymentTokenRoleOverride(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      paymentTokenAddress: paymentTokenAddress,
    );
    Logger.info('[TradeCommunityTokenService] Building route');
    final route = routeBuilder.build(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: CommunityTokenTradeMode.sell,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenRoleOverride: paymentRoleOverride,
    );

    Logger.info('[TradeCommunityTokenService] Fetching token info');
    final tokenInfo = await repository.fetchTokenInfo(externalAddress);

    Logger.info(
      '[TradeCommunityTokenService] Building quote | pricingIdentifier=$externalAddress | amountIn=$amountIn | slippagePercent=$slippagePercent',
    );
    final quote = await quoteBuilder.build(
      route: route,
      pricingIdentifier: externalAddress,
      amountIn: amountIn,
      paymentTokenAddress: paymentTokenAddress,
      slippagePercent: slippagePercent,
    );
    Logger.info('[TradeCommunityTokenService] Building user operations');
    final userOps = await userOpsBuilder.buildUserOps(
      route: route,
      quote: quote,
      walletAddress: walletAddress,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenDecimals: paymentTokenDecimals,
      communityTokenDecimals: tokenDecimals,
      communityTokenAddress: communityTokenAddress,
    );
    Logger.info('[TradeCommunityTokenService] Signing and broadcasting user operations');
    final transaction = await repository.signAndBroadcastUserOperations(
      walletId: walletId,
      userOperations: userOps,
      feeSponsorId: quote.finalPricing.feeSponsorId,
      userActionSigner: userActionSigner,
    );

    Logger.info(
      '[TradeCommunityTokenService] Swap completed | status=${transaction['status']} | isBroadcasted=${_isBroadcasted(transaction)}',
    );

    if (shouldSendEvents && _isBroadcasted(transaction)) {
      Logger.info('[TradeCommunityTokenService] Transaction broadcasted, sending sell events');
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
      Logger.info('[TradeCommunityTokenService] Sell events sent successfully');
    }

    Logger.info('[TradeCommunityTokenService] sellCommunityToken completed successfully');
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
    Future<FatAddressV2Data> Function(PricingResponse pricing)? fatAddressDataWithPricingResolver,
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
    final amountIn = BigInt.parse(amount);
    final initialRouteQuote = await _buildRouteAndQuote(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: mode,
      paymentTokenAddress: paymentTokenAddress,
      paymentRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
      pricingIdentifier: pricingIdentifier,
      amountIn: amountIn,
      slippagePercent: 0,
      fatAddressHex: _looksLikeHex(pricingIdentifier) ? pricingIdentifier : null,
    );

    return _resolveQuoteWithEnrichedFatAddress(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: mode,
      paymentTokenAddress: paymentTokenAddress,
      paymentRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
      pricingIdentifier: pricingIdentifier,
      amountIn: amountIn,
      initialRouteQuote: initialRouteQuote,
      fatAddressData: fatAddressData,
      fatAddressDataWithPricingResolver: fatAddressDataWithPricingResolver,
    );
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
    required String feeSponsorId,
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
      feeSponsorId: feeSponsorId,
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

  Future<_RouteQuote> _buildRouteAndQuote({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required CommunityTokenTradeMode mode,
    required String paymentTokenAddress,
    required TradeTokenRole? paymentRoleOverride,
    required bool isCreatorTokenMissingForContentFirstBuy,
    required String pricingIdentifier,
    required BigInt amountIn,
    required double slippagePercent,
    required String? fatAddressHex,
  }) async {
    Logger.info('[TradeCommunityTokenService] Building route');
    final route = routeBuilder.build(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: mode,
      paymentTokenAddress: paymentTokenAddress,
      paymentTokenRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
    );
    Logger.info(
      '[TradeCommunityTokenService] Building quote | pricingIdentifier=$pricingIdentifier | amountIn=$amountIn | slippagePercent=$slippagePercent',
    );
    final quote = await quoteBuilder.build(
      route: route,
      pricingIdentifier: pricingIdentifier,
      amountIn: amountIn,
      paymentTokenAddress: paymentTokenAddress,
      slippagePercent: slippagePercent,
      fatAddressHex: fatAddressHex,
    );
    return _RouteQuote(route: route, quote: quote);
  }

  Future<PricingResponse> _resolveQuoteWithEnrichedFatAddress({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required CommunityTokenTradeMode mode,
    required String paymentTokenAddress,
    required TradeTokenRole? paymentRoleOverride,
    required bool isCreatorTokenMissingForContentFirstBuy,
    required String pricingIdentifier,
    required BigInt amountIn,
    required _RouteQuote initialRouteQuote,
    required FatAddressV2Data? fatAddressData,
    required Future<FatAddressV2Data> Function(PricingResponse pricing)?
        fatAddressDataWithPricingResolver,
  }) async {
    final shouldEnrichFatAddress = mode == CommunityTokenTradeMode.buy &&
        fatAddressData != null &&
        fatAddressDataWithPricingResolver != null;
    if (!shouldEnrichFatAddress) {
      return initialRouteQuote.quote.finalPricing;
    }

    final enrichedFatAddress = await fatAddressDataWithPricingResolver(
      initialRouteQuote.quote.finalPricing,
    );
    final enrichedHex = enrichedFatAddress.toHex();
    if (enrichedHex.isEmpty || enrichedHex == pricingIdentifier) {
      return initialRouteQuote.quote.finalPricing;
    }

    final enrichedRouteQuote = await _buildRouteAndQuote(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      mode: mode,
      paymentTokenAddress: paymentTokenAddress,
      paymentRoleOverride: paymentRoleOverride,
      isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
      pricingIdentifier: enrichedHex,
      amountIn: amountIn,
      slippagePercent: 0,
      fatAddressHex: enrichedHex,
    );
    return enrichedRouteQuote.quote.finalPricing;
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
    Logger.info(
      '[TradeCommunityTokenService] _trySendBuyEvents called | externalAddress=$externalAddress | firstBuy=$firstBuy',
    );
    try {
      final txHash = transaction['txHash'] as String?;
      if (txHash == null || txHash.isEmpty) {
        Logger.error('[TradeCommunityTokenService] Transaction hash is missing');
        throw TransactionHashNotFoundException(externalAddress);
      }
      Logger.info('[TradeCommunityTokenService] Transaction hash extracted | txHash=$txHash');

      final bondingCurveAddress = await repository.fetchBondingCurveAddress();
      Logger.info(
        '[TradeCommunityTokenService] Bonding curve address fetched | bondingCurveAddress=$bondingCurveAddress',
      );

      final tokenAddress = existingTokenAddress ??
          await withRetry<String>(
            ({Object? error}) async {
              Logger.info('[TradeCommunityTokenService] Retrying to fetch token address');
              final tokenAddress =
                  _extractTokenAddress(await repository.fetchTokenInfoFresh(externalAddress));
              if (tokenAddress == null || tokenAddress.isEmpty) {
                throw TokenAddressNotFoundException(externalAddress);
              }
              return tokenAddress;
            },
            retryWhen: (error) => error is TokenAddressNotFoundException,
          );
      Logger.info(
        '[TradeCommunityTokenService] Token address obtained | tokenAddress=$tokenAddress',
      );

      final usdAmountValue = pricing.amountUSD;
      final communityTokenAmountValue = fromBlockchainUnits(pricing.amount);
      final baseTokenAmountValue = fromBlockchainUnits(
        amountIn.toString(),
        decimals: tokenDecimals,
      );

      Logger.info(
        '[TradeCommunityTokenService] Amounts calculated | baseTokenAmountValue=$baseTokenAmountValue | communityTokenAmountValue=$communityTokenAmountValue | usdAmountValue=$usdAmountValue',
      );

      final amountBase = TransactionAmount(
        value: baseTokenAmountValue,
        currency: baseTokenTicker,
      );
      final amountQuote = TransactionAmount(
        value: communityTokenAmountValue,
        currency: externalAddress,
      );
      final amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

      Logger.info(
        '[TradeCommunityTokenService] Calling sendBuyActionEvents | externalAddress=$externalAddress | network=$walletNetwork | hasUserPosition=$hasUserPosition | bondingCurveAddress=$bondingCurveAddress | tokenAddress=$tokenAddress | transactionAddress=$txHash',
      );

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

      Logger.info('[TradeCommunityTokenService] sendBuyActionEvents completed successfully');
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[TradeCommunityTokenService] Failed to send buy events for $externalAddress',
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
    Logger.info(
      '[TradeCommunityTokenService] _trySendSellEvents called | externalAddress=$externalAddress',
    );
    try {
      final txHash = transaction['txHash'] as String?;
      if (txHash == null || txHash.isEmpty) {
        Logger.error('[TradeCommunityTokenService] Transaction hash is missing');
        throw TransactionHashNotFoundException(externalAddress);
      }
      Logger.info('[TradeCommunityTokenService] Transaction hash extracted | txHash=$txHash');

      final bondingCurveAddress = await repository.fetchBondingCurveAddress();
      Logger.info(
        '[TradeCommunityTokenService] Bonding curve address fetched | bondingCurveAddress=$bondingCurveAddress',
      );

      final communityTokenAmountValue = fromBlockchainUnits(amountIn.toString());
      final paymentTokenAmountValue = fromBlockchainUnits(
        pricing.amount,
        decimals: paymentTokenDecimals,
      );

      final usdAmountValue = pricing.amountUSD;

      Logger.info(
        '[TradeCommunityTokenService] Amounts calculated | communityTokenAmountValue=$communityTokenAmountValue | paymentTokenAmountValue=$paymentTokenAmountValue | usdAmountValue=$usdAmountValue',
      );

      final amountBase =
          TransactionAmount(value: communityTokenAmountValue, currency: externalAddress);
      final amountQuote = TransactionAmount(
        value: paymentTokenAmountValue,
        currency: paymentTokenTicker,
      );
      final amountUsd = TransactionAmount(value: usdAmountValue, currency: 'USD');

      Logger.info(
        '[TradeCommunityTokenService] Calling sendSellActionEvents | externalAddress=$externalAddress | network=$walletNetwork | bondingCurveAddress=$bondingCurveAddress | tokenAddress=$communityTokenAddress | transactionAddress=$txHash',
      );

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

      Logger.info('[TradeCommunityTokenService] sendSellActionEvents completed successfully');
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[TradeCommunityTokenService] Failed to send sell events for $externalAddress',
      );
      unawaited(SentryService.logException(error, stackTrace: stackTrace));
    }
  }

  bool _isBroadcasted(TransactionResult transaction) {
    final status = transaction['status']?.toString() ?? '';
    return status.toLowerCase() == 'broadcasted';
  }

  bool _hasUserPosition(CommunityToken? tokenInfo) => tokenInfo?.marketData.position != null;

  bool _sameAddress(String? left, String? right) {
    if (left == null || right == null) return false;
    return left.toLowerCase() == right.toLowerCase();
  }

  String? _extractTokenAddress(CommunityToken? tokenInfo) => tokenInfo?.addresses.blockchain;

  Future<bool> _isFirstBuy(String externalAddress, ExternalAddressType externalAddressType) async {
    if (externalAddressType.isXToken) {
      return false;
    }

    EventReference eventReference;

    try {
      eventReference = ReplaceableEventReference.fromString(externalAddress);
    } catch (e) {
      eventReference = ImmutableEventReference(eventId: externalAddress, masterPubkey: '');
    }

    final hasFirstBuyDefinitionEvent =
        await ionConnectService.hasFirstBuyDefinitionEvent(eventReference);
    return !hasFirstBuyDefinitionEvent;
  }
}

class _RouteQuote {
  const _RouteQuote({
    required this.route,
    required this.quote,
  });

  final TradeRoutePlan route;
  final TradeQuotePlan quote;
}
