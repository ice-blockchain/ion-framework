// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/domain/content_payment_token_resolver_service.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/content_payment_token_context_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggest_token_creation_details_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details_state.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_config_cache_data.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_config_cache_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/services/pricing_identifier_resolver.dart';
import 'package:ion/app/features/tokenized_communities/services/trade_community_last_payment_coin_service.dart';
import 'package:ion/app/features/tokenized_communities/services/trade_community_token_quote_controller.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/payment_token_address_resolver.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_state.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trade_community_token_controller_provider.r.g.dart';

typedef TradeCommunityTokenControllerParams = ({
  String externalAddress,
  ExternalAddressType externalAddressType,
  EventReference? eventReference,
});

@riverpod
class TradeCommunityTokenController extends _$TradeCommunityTokenController {
  TradeCommunityTokenQuoteController? _quoteController;
  CommunityTokenPricingIdentifierResolver? _pricingIdentifierResolver;
  TradeCommunityLastPaymentCoinService? _lastPaymentCoinService;

  @override
  TradeCommunityTokenState build(TradeCommunityTokenControllerParams params) {
    final externalAddress = params.externalAddress;
    state = const TradeCommunityTokenState();

    final cached = ref.read(tradeConfigCacheProvider.notifier).get(externalAddress);
    if (cached != null) {
      state = state.copyWith(
        selectedPaymentToken: cached.selectedPaymentToken,
        paymentCoinsGroup: cached.paymentCoinsGroup,
        targetWallet: cached.targetWallet,
        targetNetwork: cached.targetNetwork,
      );
    }

    _quoteController ??= TradeCommunityTokenQuoteController(
      serviceResolver: () => ref.read(tradeCommunityTokenServiceProvider.future),
      debounce: const Duration(
        milliseconds: TokenizedCommunitiesConstants.quoteDebounceMilliseconds,
      ),
    );

    _lastPaymentCoinService ??= TradeCommunityLastPaymentCoinService(
      localStorage: ref.read(localStorageProvider),
    );

    final pubkey = params.eventReference?.masterPubkey ??
        CreatorTokenUtils.tryExtractPubkeyFromExternalAddress(externalAddress);

    _pricingIdentifierResolver ??= CommunityTokenPricingIdentifierResolver(
      externalAddress: externalAddress,
      externalAddressType: params.externalAddressType,
      tokenExistsResolver: () async {
        final tokenInfo = await ref.read(tokenMarketInfoProvider(externalAddress).future);
        final tokenAddress = tokenInfo?.addresses.blockchain?.trim() ?? '';
        return tokenAddress.isNotEmpty;
      },
      fatAddressDataResolver: () {
        return ref.read(
          fatAddressDataProvider(
            externalAddress: externalAddress,
            externalAddressType: params.externalAddressType,
            eventReference: params.eventReference,
            suggestedDetails: state.suggestedDetails,
          ).future,
        );
      },
    );

    ref
      ..listen(currentWalletViewDataProvider, (_, __) => _updateDerivedState())
      ..listen(walletsNotifierProvider, (_, __) => _updateDerivedState())
      ..listen(
        tokenMarketInfoProvider(externalAddress),
        (_, __) => _updateCommunityTokenState(),
      );
    final eventRef = params.eventReference;
    // In case this is the first buy of a content token, we need to get the AI-suggested token creation details
    if (eventRef != null && pubkey != null && params.externalAddressType.isContentToken) {
      TradeCommunityTokenState mapToTradeState(
        AsyncValue<SuggestedTokenDetailsState?> suggestedDetailsState,
      ) {
        final shouldSkipSuggestedDetails =
            suggestedDetailsState.valueOrNull is SuggestedTokenDetailsStateSkipped;

        return state.copyWith(
          suggestedDetails: suggestedDetailsState.valueOrNull?.maybeWhen(
            suggested: (details) => details,
            orElse: () => null,
          ),
          shouldWaitSuggestedDetails: !shouldSkipSuggestedDetails,
        );
      }

      ref.listen(
        suggestTokenCreationDetailsFromEventProvider(
          (
            eventReference: eventRef,
            externalAddress: externalAddress,
            pubkey: pubkey,
          ),
        ),
        (previous, current) {
          state = mapToTradeState(current);
          _updateCommunityTokenState();
        },
      );

      // Set initial loading state
      final initialAsyncValue = ref.read(
        suggestTokenCreationDetailsFromEventProvider(
          (
            eventReference: eventRef,
            externalAddress: externalAddress,
            pubkey: pubkey,
          ),
        ),
      );
      state = mapToTradeState(initialAsyncValue);
    }

    if (params.externalAddressType.isContentToken) {
      ref.listen(
        contentPaymentTokenContextProvider(
          externalAddress: externalAddress,
          externalAddressType: params.externalAddressType,
          eventReference: params.eventReference,
        ),
        (_, __) => _updateDerivedState(),
      );
    }
    if (pubkey != null) {
      ref.listen(
        userPreviewDataProvider(pubkey),
        (_, __) => _updateCommunityTokenState(),
      );
    }
    ref.onDispose(() {
      _quoteController?.dispose();
      _quoteController = null;
    });

    _initialize();
    _updateCommunityTokenState();
    _updateDerivedState();
    return state;
  }

  Future<void> _initialize() async {
    try {
      if (params.externalAddressType.isContentToken) {
        await _initializeContentPayment();
        return;
      }

      final supportedTokens = await ref.read(supportedSwapTokensProvider.future);
      if (state.selectedPaymentToken == null && supportedTokens.isNotEmpty) {
        final restoredToken = _lastPaymentCoinService!.restoreLastUsedPaymentToken(supportedTokens);
        if (restoredToken != null) {
          final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
          final paymentCoinsGroup = _derivePaymentCoinsGroup(restoredToken, walletView);
          state = state.copyWith(
            selectedPaymentToken: restoredToken,
            paymentCoinsGroup: paymentCoinsGroup,
          );
          ref.read(tradeConfigCacheProvider.notifier).save(
                params.externalAddress,
                TradeConfigCacheData(
                  selectedPaymentToken: restoredToken,
                  paymentCoinsGroup: paymentCoinsGroup,
                ),
              );
          unawaited(_updateDerivedState());
        } else {
          selectPaymentToken(supportedTokens.first);
        }
      }
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to initialize trade form',
      );
    }
  }

  Future<void> _initializeContentPayment() async {
    if (state.selectedPaymentToken != null && state.paymentCoinsGroup != null) {
      return;
    }

    try {
      final paymentContext = await ref.read(
        contentPaymentTokenContextProvider(
          externalAddress: params.externalAddress,
          externalAddressType: params.externalAddressType,
          eventReference: params.eventReference,
        ).future,
      );
      final paymentToken = paymentContext?.token;
      if (paymentToken == null) {
        throw StateError('Creator payment token is missing.');
      }

      final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
      final resolvedGroup = _derivePaymentCoinsGroup(paymentToken, walletView);
      state = state.copyWith(
        selectedPaymentToken: paymentToken,
        paymentCoinsGroup: resolvedGroup,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to resolve content payment token',
      );
      state = state.copyWith(
        selectedPaymentToken: null,
        paymentCoinsGroup: null,
        targetWallet: null,
        targetNetwork: null,
      );
    }
  }

  Future<void> _updateCommunityTokenState() async {
    final externalAddress = params.externalAddress;
    final tokenInfo = ref.read(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    final balance = tokenInfo?.marketData.position?.amountValue ?? 0.0;

    final pubkey = params.eventReference?.masterPubkey ??
        CreatorTokenUtils.tryExtractPubkeyFromExternalAddress(externalAddress);
    final userData = pubkey == null ? null : ref.read(userPreviewDataProvider(pubkey)).valueOrNull;

    String? tokenTitle;
    String tokenTicker;
    String? communityAvatar;

    if (state.shouldWaitSuggestedDetails) {
      final suggestedDetails = state.suggestedDetails;
      tokenTitle = suggestedDetails?.name.trim() ?? '';
      tokenTicker = suggestedDetails?.ticker.trim() ?? '';
      communityAvatar = suggestedDetails?.picture.trim();
    } else {
      tokenTitle = tokenInfo?.title ??
          userData?.data.trimmedDisplayName ??
          userData?.data.name ??
          pubkey ??
          externalAddress;

      tokenTicker = tokenInfo?.marketData.ticker ?? '';

      communityAvatar = tokenInfo?.imageUrl ?? userData?.data.avatarUrl;
    }
    final interimState = state.copyWith(
      communityTokenBalance: balance,
      communityTokenCoinsGroup: _buildCommunityTokenGroup(
        baseGroup: state.communityTokenCoinsGroup,
        tokenTitle: tokenTitle,
        tokenTicker: tokenTicker,
        communityAvatar: communityAvatar,
      ),
    );
    state = interimState;

    final derivedCoinsGroup = await _deriveCommunityTokenCoinsGroup(tokenInfo);
    if (derivedCoinsGroup == null) return;

    final finalState = state.copyWith(
      communityTokenBalance: balance,
      communityTokenCoinsGroup: _buildCommunityTokenGroup(
        baseGroup: derivedCoinsGroup,
        tokenTitle: tokenTitle,
        tokenTicker: tokenTicker,
        communityAvatar: communityAvatar,
      ),
    );
    state = finalState;
  }

  Future<CoinsGroup?> _deriveCommunityTokenCoinsGroup(
    CommunityToken? token,
  ) async {
    if (token == null) return null;

    final wallets = ref.read(walletsNotifierProvider).valueOrNull ?? [];
    final bscWallet = CreatorTokenUtils.findBscWallet(wallets);

    if (bscWallet == null) return null;

    final network = await ref.read(networkByIdProvider(bscWallet.network).future);
    if (network == null) return null;

    final contractAddress = token.addresses.blockchain?.trim() ?? '';
    final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
    if (walletView == null || contractAddress.isEmpty) {
      return CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
        token: token,
        externalAddress: params.externalAddress,
        network: network,
      );
    }

    final contractLower = contractAddress.toLowerCase();
    final contractNetworkMatches = walletView.coinGroups.where(
      (g) => g.coins.any(
        (c) =>
            c.coin.network.id == network.id &&
            c.coin.contractAddress.toLowerCase() == contractLower,
      ),
    );

    if (contractNetworkMatches.isEmpty) {
      return CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
        token: token,
        externalAddress: params.externalAddress,
        network: network,
      );
    }

    // Prefer groups that are linked to a real wallet (walletId != null).
    // symbolGroup is used only to choose between groups that already
    // match the same contract + network.
    final walletBoundGroups = contractNetworkMatches
        .where(
          (g) => g.coins.any((c) => c.walletId != null),
        )
        .toList();

    if (walletBoundGroups.isNotEmpty) {
      final ticker = token.marketData.ticker?.trim().toLowerCase() ?? '';

      if (ticker.isNotEmpty) {
        final byTicker = walletBoundGroups.firstWhereOrNull(
          (g) => g.symbolGroup.toLowerCase() == ticker,
        );

        if (byTicker != null) return byTicker;
      }

      return walletBoundGroups.first;
    }

    return contractNetworkMatches.first;
  }

  void setMode(CommunityTokenTradeMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    _resetTradeFormOnModeChange();
    _updateDerivedState();
    _refreshFormattedAmounts();
  }

  void toggleMode() {
    setMode(
      state.mode == CommunityTokenTradeMode.buy
          ? CommunityTokenTradeMode.sell
          : CommunityTokenTradeMode.buy,
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
    _scheduleQuoteUpdates();
    _refreshFormattedAmounts();
  }

  void setAmountByPercentage(int percentage) {
    final mode = state.mode;

    if (mode == CommunityTokenTradeMode.buy) {
      final coinsGroup = state.paymentCoinsGroup;
      if (coinsGroup == null) return;

      final totalAmount = coinsGroup.totalAmount;
      final amount = (totalAmount * percentage / TokenizedCommunitiesConstants.percentageDivisor)
          .clamp(0.0, totalAmount);
      setAmount(amount);
    } else {
      // Sell mode: use community token balance
      final balance = state.communityTokenBalance;
      if (balance <= 0) return;

      final amount = (balance * percentage / TokenizedCommunitiesConstants.percentageDivisor)
          .clamp(0.0, balance);
      setAmount(amount);
    }
  }

  void selectPaymentToken(CoinData token) {
    state = state.copyWith(selectedPaymentToken: token);
    _lastPaymentCoinService!.saveLastUsedPaymentToken(token);
    _updateDerivedState();
    _scheduleQuoteUpdates();
    _refreshFormattedAmounts();
  }

  void setSlippage(double slippage) {
    state = state.copyWith(slippage: slippage);
  }

  void setShouldSendEvents({required bool send}) {
    state = state.copyWith(shouldSendEvents: send);
  }

  void _resetTradeFormOnModeChange() {
    _quoteController?.cancel();
    state = state.copyWith(
      amount: 0,
      quotePricing: null,
      isQuoting: false,
      communityTokenAmountUSDFormatted: null,
      paymentTokenAmountUSDFormatted: null,
      paymentTokenQuoteAmountUSDFormatted: null,
    );
  }

  Future<void> _updateDerivedState() async {
    final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;

    final paymentContext = await _resolvePaymentContext(walletView);
    final paymentToken = paymentContext.token;
    final paymentCoinsGroup = paymentContext.coinsGroup;
    if (paymentToken == null || paymentCoinsGroup == null) {
      state = state.copyWith(
        selectedPaymentToken: null,
        paymentCoinsGroup: null,
        targetWallet: null,
        targetNetwork: null,
      );
      return;
    }

    final (targetWallet, targetNetwork) = state.mode == CommunityTokenTradeMode.sell
        ? await _updateDerivedStateForSell()
        : await _updateDerivedStateForBuy(paymentToken, paymentCoinsGroup);

    state = state.copyWith(
      selectedPaymentToken: paymentToken,
      paymentCoinsGroup: paymentCoinsGroup,
      targetWallet: targetWallet,
      targetNetwork: targetNetwork,
    );

    ref.read(tradeConfigCacheProvider.notifier).save(
          params.externalAddress,
          TradeConfigCacheData(
            selectedPaymentToken: paymentToken,
            paymentCoinsGroup: paymentCoinsGroup,
            targetWallet: targetWallet,
            targetNetwork: targetNetwork,
          ),
        );

    _refreshFormattedAmounts();
  }

  Future<({CoinData? token, CoinsGroup? coinsGroup})> _resolvePaymentContext(
    WalletViewData? walletView,
  ) async {
    if (params.externalAddressType.isContentToken) {
      try {
        final paymentContext = await ref.read(
          contentPaymentTokenContextProvider(
            externalAddress: params.externalAddress,
            externalAddressType: params.externalAddressType,
            eventReference: params.eventReference,
          ).future,
        );
        if (paymentContext == null) {
          return (token: null, coinsGroup: null);
        }

        final token = state.selectedPaymentToken ?? paymentContext.token;
        final selected = state.selectedPaymentToken;
        final sameAsContext = selected == null ||
            selected.contractAddress.toLowerCase() ==
                paymentContext.token.contractAddress.toLowerCase();
        final derivedGroup = _derivePaymentCoinsGroup(token, walletView);
        final coinsGroup = sameAsContext
            ? (paymentContext.source == ContentPaymentTokenSource.supportedTokenFallback
                ? derivedGroup
                : paymentContext.coinsGroup)
            : derivedGroup;
        return (token: token, coinsGroup: coinsGroup);
      } catch (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to resolve content payment token',
        );
        return (token: null, coinsGroup: null);
      }
    }

    final token = state.selectedPaymentToken;
    if (token == null) return (token: null, coinsGroup: null);

    final paymentCoinsGroup = _derivePaymentCoinsGroup(token, walletView);
    return (token: token, coinsGroup: paymentCoinsGroup);
  }

  Future<(Wallet?, NetworkData?)> _updateDerivedStateForBuy(
    CoinData paymentToken,
    CoinsGroup paymentCoinsGroup,
  ) async {
    final wallets = ref.read(walletsNotifierProvider).valueOrNull ?? [];
    final targetWallet = _findTargetWallet(paymentToken, paymentCoinsGroup, wallets);
    final targetNetwork = await _loadTargetNetwork(targetWallet);
    return (targetWallet, targetNetwork);
  }

  Future<(Wallet?, NetworkData?)> _updateDerivedStateForSell() async {
    final wallets = ref.read(walletsNotifierProvider).valueOrNull ?? [];
    final bscWallet = CreatorTokenUtils.findBscWallet(wallets);
    if (bscWallet == null || bscWallet.address == null) {
      return (null, null);
    }
    final targetNetwork = await _loadTargetNetwork(bscWallet);
    return (bscWallet, targetNetwork);
  }

  CoinsGroup _derivePaymentCoinsGroup(
    CoinData paymentToken,
    WalletViewData? walletView,
  ) {
    final group = walletView?.coinGroups.firstWhereOrNull((g) {
      return g.coins.any((c) {
        if (c.coin.network.id != paymentToken.network.id) return false;
        final contract = paymentToken.contractAddress.trim().toLowerCase();
        if (contract.isEmpty) {
          return c.coin.native;
        }
        return c.coin.contractAddress.trim().toLowerCase() == contract;
      });
    });
    if (group != null) return group;

    final symbolGroupMatch = walletView?.coinGroups.firstWhereOrNull(
      (g) => g.symbolGroup == paymentToken.symbolGroup,
    );
    return symbolGroupMatch ?? CoinsGroup.fromCoin(paymentToken);
  }

  Wallet? _findTargetWallet(
    CoinData paymentToken,
    CoinsGroup coinsGroup,
    List<Wallet> wallets,
  ) {
    final walletWithToken = _findWalletWithToken(
      paymentToken,
      coinsGroup,
      wallets,
    );
    if (walletWithToken != null) return walletWithToken;

    return wallets.firstWhereOrNull((w) => w.network == paymentToken.network.id);
  }

  Wallet? _findWalletWithToken(
    CoinData paymentToken,
    CoinsGroup coinsGroup,
    List<Wallet> wallets,
  ) {
    final coinInWallet = coinsGroup.coins.firstWhereOrNull(
      (c) =>
          c.coin.network.id == paymentToken.network.id &&
          c.coin.contractAddress.toLowerCase() == paymentToken.contractAddress.toLowerCase(),
    );

    if (coinInWallet?.walletId == null) return null;

    return wallets.firstWhereOrNull((w) => w.id == coinInWallet!.walletId);
  }

  Future<NetworkData?> _loadTargetNetwork(Wallet? targetWallet) async {
    if (targetWallet == null) return null;
    return ref.read(networkByIdProvider(targetWallet.network).future);
  }

  void _scheduleQuoteUpdates() {
    final quoteController = _quoteController;
    if (quoteController == null) return;

    quoteController.schedule(
      request: _buildQuoteRequest(),
      onReset: () {
        _setQuotePricing(null);
      },
      onStart: () => state = state.copyWith(isQuoting: true),
      onSuccess: _setQuotePricing,
      onError: (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to get quote',
        );
        _setQuotePricing(null);
      },
      onPollError: (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to refresh quote',
        );
      },
    );
  }

  TradeCommunityTokenQuoteRequest? _buildQuoteRequest() {
    try {
      final token = state.selectedPaymentToken;
      if (token == null) return null;

      final mode = state.mode;

      // Pricing API expects amount in smallest units (wei).
      final amountDecimals = mode == CommunityTokenTradeMode.sell
          ? TokenizedCommunitiesConstants.creatorTokenDecimals
          : token.decimals;

      return TradeCommunityTokenQuoteRequest(
        externalAddress: params.externalAddress,
        externalAddressType: params.externalAddressType,
        mode: mode,
        amount: state.amount,
        amountDecimals: amountDecimals,
        pricingIdentifierResolver: () => _resolvePricingIdentifier(mode),
        paymentTokenAddress: resolvePaymentTokenAddress(token),
        fatAddressDataWithPricingResolver: (pricing) {
          return ref.read(
            fatAddressDataProvider(
              externalAddress: params.externalAddress,
              externalAddressType: params.externalAddressType,
              eventReference: params.eventReference,
              suggestedDetails: state.suggestedDetails,
              pricing: pricing,
            ).future,
          );
        },
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to build quote request',
      );
      state = state.copyWith(
        quotePricing: null,
        isQuoting: false,
      );
      return null;
    }
  }

  Future<PricingIdentifierResolution> _resolvePricingIdentifier(
    CommunityTokenTradeMode mode,
  ) async {
    final resolver = _pricingIdentifierResolver;
    if (resolver == null) {
      throw StateError('CommunityTokenPricingIdentifierResolver is not initialized');
    }
    return resolver.resolve(mode);
  }

  void _setQuotePricing(PricingResponse? pricing) {
    final formatted = _computeFormattedAmounts(pricing);
    state = state.copyWith(
      quotePricing: pricing,
      isQuoting: false,
      communityTokenAmountUSDFormatted: formatted.community,
      paymentTokenAmountUSDFormatted: formatted.payment,
      paymentTokenQuoteAmountUSDFormatted: formatted.paymentQuote,
    );
  }

  void _refreshFormattedAmounts() {
    final formatted = _computeFormattedAmounts(state.quotePricing);
    state = state.copyWith(
      communityTokenAmountUSDFormatted: formatted.community,
      paymentTokenAmountUSDFormatted: formatted.payment,
      paymentTokenQuoteAmountUSDFormatted: formatted.paymentQuote,
    );
  }

  ({String? community, String? payment, String? paymentQuote}) _computeFormattedAmounts(
    PricingResponse? pricing,
  ) {
    final community = pricing == null ? null : formatToCurrency(pricing.amountUSD);
    if (pricing == null) {
      final zero = formatToCurrency(0);
      return (community: community, payment: zero, paymentQuote: zero);
    }

    final paymentTokenPriceUSD = _resolvePaymentTokenPriceUSD(pricing);
    final payment =
        paymentTokenPriceUSD == null ? null : formatToCurrency(state.amount * paymentTokenPriceUSD);

    String? paymentQuote;
    if (paymentTokenPriceUSD != null && state.mode == CommunityTokenTradeMode.sell) {
      final decimals = state.selectedPaymentToken?.decimals;
      if (decimals != null) {
        final quoteAmount = fromBlockchainUnits(pricing.amount, decimals);
        paymentQuote = formatToCurrency(quoteAmount * paymentTokenPriceUSD);
      }
    }

    return (community: community, payment: payment, paymentQuote: paymentQuote);
  }

  double? _resolvePaymentTokenPriceUSD(PricingResponse? pricing) {
    if (pricing == null) return null;
    final token = state.selectedPaymentToken?.abbreviation.toUpperCase();
    if (token == null) return null;

    final tokenMap = {
      'ION': pricing.usdPriceION,
      'TION': pricing.usdPriceION,
      'BNB': pricing.usdPriceBNB,
    };

    return tokenMap[token];
  }

  CoinsGroup _buildCommunityTokenGroup({
    required CoinsGroup? baseGroup,
    required String tokenTitle,
    required String tokenTicker,
    required String? communityAvatar,
  }) {
    // Use user name as fallback when ticker is empty (e.g., first buy)
    final tokenName = tokenTicker.isNotEmpty ? tokenTicker : tokenTitle;
    final group = baseGroup ??
        CoinsGroup(
          name: tokenTitle,
          iconUrl: communityAvatar,
          symbolGroup: tokenName,
          abbreviation: tokenName,
          coins: const [],
        );
    return group.copyWith(
      name: tokenTitle,
      iconUrl: communityAvatar ?? group.iconUrl,
      symbolGroup: tokenName,
      abbreviation: tokenName,
    );
  }
}
