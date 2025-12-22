// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/fat_address_data_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/services/trade_community_token_quote_controller.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_state.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
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
  late final TradeCommunityTokenQuoteController _quoteController;

  @override
  TradeCommunityTokenState build(TradeCommunityTokenControllerParams params) {
    final externalAddress = params.externalAddress;
    state = const TradeCommunityTokenState();

    _quoteController = TradeCommunityTokenQuoteController(
      serviceResolver: () => ref.read(tradeCommunityTokenServiceProvider.future),
      debounce: const Duration(
        milliseconds: TokenizedCommunitiesConstants.quoteDebounceMilliseconds,
      ),
    );

    final pubkey = params.eventReference?.masterPubkey ??
        CreatorTokenUtils.tryExtractPubkeyFromExternalAddress(externalAddress);

    ref
      ..listen(currentWalletViewDataProvider, (_, __) => _updateDerivedState())
      ..listen(walletsNotifierProvider, (_, __) => _updateDerivedState())
      ..listen(
        tokenMarketInfoProvider(externalAddress),
        (_, __) => _updateCommunityTokenState(),
      );
    if (pubkey != null) {
      ref.listen(
        userPreviewDataProvider(pubkey),
        (_, __) => _updateCommunityTokenState(),
      );
    }
    ref.onDispose(() {
      _quoteController.dispose();
    });

    _initialize();
    _updateCommunityTokenState();
    _updateDerivedState();
    return state;
  }

  Future<void> _initialize() async {
    final supportedTokens = await ref.watch(supportedSwapTokensProvider.future);

    if (state.selectedPaymentToken == null && supportedTokens.isNotEmpty) {
      selectPaymentToken(supportedTokens.first);
    }
  }

  Future<void> _updateCommunityTokenState() async {
    final externalAddress = params.externalAddress;
    final tokenInfo = ref.read(tokenMarketInfoProvider(externalAddress)).valueOrNull;
    final balance = tokenInfo?.marketData.position?.amountValue ?? 0.0;

    final pubkey = params.eventReference?.masterPubkey ??
        CreatorTokenUtils.tryExtractPubkeyFromExternalAddress(externalAddress);
    final userData = pubkey == null ? null : ref.read(userPreviewDataProvider(pubkey)).valueOrNull;

    final tokenTitle = tokenInfo?.title ??
        userData?.data.trimmedDisplayName ??
        userData?.data.name ??
        pubkey ??
        externalAddress;

    final communityAvatar = tokenInfo?.imageUrl ?? userData?.data.avatarUrl;

    final interimState = state.copyWith(
      communityTokenBalance: balance,
      communityTokenCoinsGroup: _buildInterimCommunityTokenGroup(
        tokenTitle: tokenTitle,
        communityAvatar: communityAvatar,
      ),
    );
    state = interimState;

    final derivedCoinsGroup = await _deriveCommunityTokenCoinsGroup(tokenInfo);
    if (derivedCoinsGroup == null) return;

    final finalState = state.copyWith(
      communityTokenBalance: balance,
      communityTokenCoinsGroup: _buildFinalCommunityTokenGroup(
        derivedCoinsGroup: derivedCoinsGroup,
        tokenTitle: tokenTitle,
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

    return CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
      token: token,
      externalAddress: params.externalAddress,
      network: network,
    );
  }

  void setMode(CommunityTokenTradeMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    _resetTradeFormOnModeChange();
    _updateDerivedState();
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
    _updateDerivedState();
    _scheduleQuoteUpdates();
  }

  void setShouldSendEvents({required bool send}) {
    state = state.copyWith(shouldSendEvents: send);
  }

  void _resetTradeFormOnModeChange() {
    _quoteController.cancel();
    state = state.copyWith(
      amount: 0,
      quotePricing: null,
      isQuoting: false,
    );
  }

  Future<void> _updateDerivedState() async {
    final paymentToken = state.selectedPaymentToken;
    if (paymentToken == null) {
      state = state.copyWith(
        paymentCoinsGroup: null,
        targetWallet: null,
        targetNetwork: null,
      );
      return;
    }

    final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
    final paymentCoinsGroup = _derivePaymentCoinsGroup(paymentToken, walletView);

    final (targetWallet, targetNetwork) = state.mode == CommunityTokenTradeMode.sell
        ? await _updateDerivedStateForSell()
        : await _updateDerivedStateForBuy(paymentToken, paymentCoinsGroup);

    state = state.copyWith(
      paymentCoinsGroup: paymentCoinsGroup,
      targetWallet: targetWallet,
      targetNetwork: targetNetwork,
    );
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
    final group = walletView?.coinGroups.firstWhereOrNull(
      (g) => g.symbolGroup == paymentToken.symbolGroup,
    );
    return group ?? CoinsGroup.fromCoin(paymentToken);
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
    _quoteController.schedule(
      request: _buildQuoteRequest(),
      onReset: () {
        state = state.copyWith(
          isQuoting: false,
          quotePricing: null,
        );
      },
      onStart: () => state = state.copyWith(isQuoting: true),
      onSuccess: (pricing) {
        state = state.copyWith(
          quotePricing: pricing,
          isQuoting: false,
        );
      },
      onError: (error, stackTrace) {
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Failed to get quote',
        );
        state = state.copyWith(
          quotePricing: null,
          isQuoting: false,
        );
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
    final token = state.selectedPaymentToken;
    if (token == null) return null;

    final mode = state.mode;

    // Pricing API expects amount in smallest units (wei).
    final amountDecimals = mode == CommunityTokenTradeMode.sell
        ? TokenizedCommunitiesConstants.creatorTokenDecimals
        : token.decimals;

    return TradeCommunityTokenQuoteRequest(
      externalAddress: params.externalAddress,
      mode: mode,
      amount: state.amount,
      amountDecimals: amountDecimals,
      pricingIdentifierResolver: () => _resolvePricingIdentifier(mode),
    );
  }

  Future<String> _resolvePricingIdentifier(CommunityTokenTradeMode mode) async {
    final externalAddress = params.externalAddress;

    if (mode == CommunityTokenTradeMode.sell) {
      return externalAddress;
    }

    final tokenInfo = await ref.read(tokenMarketInfoProvider(externalAddress).future);
    final tokenAddress = tokenInfo?.addresses.blockchain;
    final tokenExists = tokenAddress != null && tokenAddress.isNotEmpty;
    if (tokenExists) {
      return externalAddress;
    }

    final fatAddressData = await ref.read(
      fatAddressDataProvider(
        externalAddress: externalAddress,
        externalAddressType: params.externalAddressType,
        eventReference: params.eventReference,
      ).future,
    );
    return fatAddressData.toFatAddressHex();
  }

  CoinsGroup _buildInterimCommunityTokenGroup({
    required String tokenTitle,
    required String? communityAvatar,
  }) {
    final existingGroup = state.communityTokenCoinsGroup;
    return existingGroup?.copyWith(
          name: tokenTitle,
          iconUrl: communityAvatar ?? existingGroup.iconUrl,
          symbolGroup: tokenTitle,
          abbreviation: tokenTitle,
        ) ??
        CoinsGroup(
          name: tokenTitle,
          iconUrl: communityAvatar,
          symbolGroup: tokenTitle,
          abbreviation: tokenTitle,
          coins: const [],
        );
  }

  CoinsGroup _buildFinalCommunityTokenGroup({
    required CoinsGroup derivedCoinsGroup,
    required String tokenTitle,
    required String? communityAvatar,
  }) {
    return derivedCoinsGroup.copyWith(
      name: tokenTitle,
      iconUrl: communityAvatar ?? derivedCoinsGroup.iconUrl,
      symbolGroup: tokenTitle,
      abbreviation: tokenTitle,
    );
  }
}
