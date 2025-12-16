// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/send_asset_form_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/network_fee_provider.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/wallet_address_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/exceptions/insufficient_balance_exception.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/ion_swap_client/ion_swap_client_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/exceptions/exolix_exceptions.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_network.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_coins_controller_provider.r.g.dart';

typedef OnVerifyIdentitySwapCallback = Future<void> Function(SendAssetFormData);

@Riverpod(keepAlive: true)
class SwapCoinsController extends _$SwapCoinsController {
  Timer? _debounceTimer;
  static const _lastSellCoinKey = 'Swap:lastSellCoinSymbolGroup';

  @override
  SwapCoinData build() => SwapCoinData();

  void initSellCoin({
    required CoinsGroup? coin,
    required NetworkData? network,
  }) =>
      state = state.copyWith(
        sellCoin: coin ?? _resolveDefaultSellCoin(),
        sellNetwork: coin != null
            ? network ?? coin.coins.firstOrNull?.coin.network
            : network ?? _resolveDefaultSellNetwork(),
        buyCoin: null,
        buyNetwork: null,
        swapQuoteInfo: null,
        amount: 0,
        isQuoteLoading: false,
        quoteAmount: null,
        quoteError: null,
        isSwapLoading: false,
      );

  void setSlippage(double slippagePercent) {
    state = state.copyWith(slippage: slippagePercent);
  }

  void setAmount(double amount) {
    state = state.copyWith(
      amount: amount,
    );

    if (state.swapQuoteInfo == null) {
      _debouncedGetQuotes();
    }
  }

  Future<bool> isBalanceSufficient() async {
    final sellCoin = state.sellCoin;
    final sellNetwork = state.sellNetwork;
    final amount = state.amount;

    if (sellCoin == null || sellNetwork == null || amount <= 0) {
      return true;
    }

    final sellCoinInWallet = await _getCoinWalletDataAndSyncIfNeeded(
      sellCoin,
      sellNetwork,
    );
    if (sellCoinInWallet == null) {
      return true;
    }

    return sellCoinInWallet.amount >= amount;
  }

  void setSellCoin(CoinsGroup? coin) {
    state = state.copyWith(
      sellCoin: coin,
    );

    if (coin != null) {
      _persistLastSellCoin(coin.symbolGroup);
    }
  }

  void setSellNetwork(NetworkData? network) {
    state = state.copyWith(
      sellNetwork: network,
    );

    if (network != null && state.swapQuoteInfo == null) {
      _debouncedGetQuotes();
    }
  }

  void setBuyCoin(CoinsGroup? coin) {
    state = state.copyWith(
      buyCoin: coin,
    );
  }

  void setBuyNetwork(NetworkData? network) {
    state = state.copyWith(
      buyNetwork: network,
    );

    if (network != null) {
      _getQuotes();
    }
  }

  void switchCoins() {
    final sellCoin = state.sellCoin;
    final buyCoin = state.buyCoin;
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final amount = state.amount;
    final swapQuoteInfo = state.swapQuoteInfo;

    state = state.copyWith(
      sellCoin: buyCoin,
      buyCoin: sellCoin,
      sellNetwork: buyNetwork,
      buyNetwork: sellNetwork,
    );

    if (swapQuoteInfo != null) {
      final quoteAmount = swapQuoteInfo.priceForSellTokenInBuyToken * amount;
      state = state.copyWith(
        amount: quoteAmount,
      );
    }

    _getQuotes();
  }

  Future<({CoinsGroup? coin, NetworkData? network})> selectCoin({
    required CoinSwapType type,
    required CoinsGroup coin,
    required Future<NetworkData?> Function() selectNetworkRouteLocationBuilder,
  }) async {
    final previousCoin = switch (type) {
      CoinSwapType.sell => state.sellCoin,
      CoinSwapType.buy => state.buyCoin,
    };
    final previousNetwork = switch (type) {
      CoinSwapType.sell => state.sellNetwork,
      CoinSwapType.buy => state.buyNetwork,
    };

    switch (type) {
      case CoinSwapType.sell:
        setSellCoin(coin);
        setSellNetwork(null);
      case CoinSwapType.buy:
        setBuyCoin(coin);
        setBuyNetwork(null);
    }

    final result = await selectNetworkRouteLocationBuilder();
    if (result != null) {
      switch (type) {
        case CoinSwapType.sell:
          setSellNetwork(result);
        case CoinSwapType.buy:
          setBuyNetwork(result);
      }
      if (type == CoinSwapType.sell) {
        _persistLastSellCoin(coin.symbolGroup);
      }
      return (
        coin: switch (type) {
          CoinSwapType.sell => state.sellCoin,
          CoinSwapType.buy => state.buyCoin
        },
        network: switch (type) {
          CoinSwapType.sell => state.sellNetwork,
          CoinSwapType.buy => state.buyNetwork
        },
      );
    } else {
      switch (type) {
        case CoinSwapType.sell:
          setSellCoin(previousCoin);
          setSellNetwork(previousNetwork);
        case CoinSwapType.buy:
          setBuyCoin(previousCoin);
          setBuyNetwork(previousNetwork);
      }
      return (coin: null, network: null);
    }
  }

  CoinsGroup? _resolveDefaultSellCoin() {
    final localStorage = ref.read(localStorageProvider);
    final lastSymbolGroup = localStorage.getString(_lastSellCoinKey);

    final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
    final coinGroups = walletView?.coinGroups;
    if (coinGroups == null || coinGroups.isEmpty) return null;

    // Try last used sell coin first
    final lastUsed = coinGroups.firstWhereOrNull(
      (group) => group.symbolGroup == lastSymbolGroup,
    );
    if (lastUsed != null) return lastUsed;

    // Otherwise pick the coin with the highest balance
    return maxBy<CoinsGroup, double>(coinGroups, (g) => g.totalAmount);
  }

  NetworkData? _resolveDefaultSellNetwork() {
    final sellCoin = _resolveDefaultSellCoin();
    return sellCoin?.coins.firstOrNull?.coin.network;
  }

  void _persistLastSellCoin(String symbolGroup) {
    ref.read(localStorageProvider).setString(_lastSellCoinKey, symbolGroup);
  }

  Future<SwapCoinParameters?> _buildSwapCoinParameters({
    required CoinsGroup sellCoinGroup,
    required NetworkData sellNetwork,
    required CoinsGroup buyCoinGroup,
    required NetworkData buyNetwork,
    required double amount,
    required String slippage,
  }) async {
    final sellAddress = await _getAddress(sellCoinGroup, sellNetwork);
    final buyAddress = await _getAddress(buyCoinGroup, buyNetwork);

    final sellCoin = await _getCoinWalletDataAndSyncIfNeeded(sellCoinGroup, sellNetwork);
    final buyCoin = await _getCoinWalletDataAndSyncIfNeeded(buyCoinGroup, buyNetwork);

    if (sellCoin == null || buyCoin == null) {
      return null;
    }

    return SwapCoinParameters(
      slippage: slippage,
      buyCoin: SwapCoin(
        contractAddress: buyCoin.coin.contractAddress,
        network: SwapNetwork(
          id: buyNetwork.id,
          name: _getSwapNetworkName(buyNetwork),
        ),
        code: buyCoin.coin.abbreviation,

        /// it's extra id used for some coins
        /// since ion provides only personal wallets for use it's fixed
        extraId: buyNetwork.isMemoSupported ? 'Online' : '',
        decimal: buyCoin.coin.decimals,
      ),
      sellCoin: SwapCoin(
        contractAddress: sellCoin.coin.contractAddress,
        network: SwapNetwork(
          id: sellNetwork.id,
          name: _getSwapNetworkName(sellNetwork),
        ),
        code: sellCoin.coin.abbreviation,
        extraId: '',
        decimal: sellCoin.coin.decimals,
      ),
      isBridge: buyCoinGroup == sellCoinGroup,
      amount: amount.toString(),
      userBuyAddress: buyAddress,
      userSellAddress: sellAddress,
    );
  }

  Future<CoinInWalletData?> _getCoinWalletDataAndSyncIfNeeded(
    CoinsGroup coinsGroup,
    NetworkData network,
  ) async {
    var coin = coinsGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == network.id);
    if (coin == null) {
      final coinsList =
          await ref.read(syncedCoinsBySymbolGroupProvider(coinsGroup.symbolGroup).future);
      coin = coinsList.firstWhereOrNull((coin) => coin.coin.network.id == network.id);
    }

    return coin;
  }

  Future<String?> _getAddress(CoinsGroup coinsGroup, NetworkData network) async {
    final address = await ref
        .read(walletAddressNotifierProvider.notifier)
        .loadWalletAddress(network: network, coinsGroup: coinsGroup);

    return address;
  }

  String _getSwapNetworkName(NetworkData network) {
    if (network.isBsc) {
      return 'BNB';
    }
    return network.displayName;
  }

  Future<void> swapCoins({
    required OnVerifyIdentitySwapCallback onVerifyIdentitySwapCallback,
    required VoidCallback onSwapSuccess,
    required VoidCallback onSwapError,
    required VoidCallback onSwapStart,
  }) async {
    try {
      state = state.copyWith(isSwapLoading: true);
      final (:swapQuoteInfo, :swapCoinParameters, :sellNetwork, :sellCoin) = await _getData();
      final swapController = await ref.read(ionSwapClientProvider.future);

      await swapController.swapCoins(
        swapQuoteInfo: swapQuoteInfo,
        swapCoinData: swapCoinParameters,
        sendCoinCallback: ({
          required String depositAddress,
          required num amount,
        }) async {
          try {
            onSwapStart();

            final sellAddress = swapCoinParameters.userSellAddress;
            if (sellAddress == null) {
              onSwapError();
              return;
            }

            await _sendCoinCallback(
              depositAddress: depositAddress,
              amount: amount,
              onVerifyIdentitySwapCallback: onVerifyIdentitySwapCallback,
              memo: sellNetwork.isMemoSupported ? 'Online' : null,
              sellAddress: sellAddress,
              sellNetwork: sellNetwork,
              sellCoinInWallet: sellCoin,
            );

            onSwapSuccess();
          } catch (e) {
            onSwapError();
            rethrow;
          }
        },
      );
    } catch (e, stackTrace) {
      onSwapError();

      await SentryService.logException(
        e,
        stackTrace: stackTrace,
        tag: 'swap_coins_failure',
      );

      throw Exception(
        'Failed to swap coins: $e',
      );
    } finally {
      state = state.copyWith(isSwapLoading: false);
    }
  }

  /// Used to send coins to address in cases where
  /// we need to send coins by ourselves to blockchain
  Future<void> _sendCoinCallback({
    required String sellAddress,
    required CoinInWalletData sellCoinInWallet,
    required NetworkData sellNetwork,
    required String depositAddress,
    required num amount,
    required OnVerifyIdentitySwapCallback onVerifyIdentitySwapCallback,
    required String? memo,
  }) async {
    final walletView = await ref.read(walletViewByAddressProvider(sellAddress).future);

    final wallets = await ref.read(
      walletViewCryptoWalletsProvider(walletViewId: walletView?.id).future,
    );

    final senderWallet = wallets.firstWhereOrNull(
      (wallet) => wallet.network == sellNetwork.id,
    );

    final networkFeeInfo = await ref.read(
      networkFeeProvider(
        walletId: senderWallet?.id,
        network: sellNetwork,
        transferredCoin: sellCoinInWallet.coin,
      ).future,
    );

    await onVerifyIdentitySwapCallback(
      SendAssetFormData(
        arrivalDateTime: DateTime.now().microsecondsSinceEpoch,
        receiverAddress: depositAddress,
        assetData: CryptoAssetToSendData.coin(
          coinsGroup: state.sellCoin!,
          amount: amount.toDouble(),
          associatedAssetWithSelectedOption: networkFeeInfo?.sendableAsset,
          selectedOption: sellCoinInWallet,
        ),
        memo: memo,
        walletView: walletView,
        network: sellNetwork,
        networkFeeOptions: networkFeeInfo?.networkFeeOptions ?? [],
        selectedNetworkFeeOption: networkFeeInfo?.networkFeeOptions.firstOrNull,
        networkNativeToken: networkFeeInfo?.networkNativeToken,
        senderWallet: senderWallet,
      ),
    );
  }

  void _debouncedGetQuotes() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _getQuotes);
  }

  Future<void> _getQuotes() async {
    if (!(await isBalanceSufficient())) {
      _setQuoteError(InsufficientBalanceException());
      return;
    }

    final sellCoin = state.sellCoin;
    final buyCoin = state.buyCoin;
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final amount = state.amount;
    if (amount <= 0 ||
        sellCoin == null ||
        sellNetwork == null ||
        buyCoin == null ||
        buyNetwork == null) {
      return;
    }

    final swapCoinParameters = await _buildSwapCoinParameters(
      sellCoinGroup: sellCoin,
      sellNetwork: sellNetwork,
      buyCoinGroup: buyCoin,
      buyNetwork: buyNetwork,
      amount: amount,
      slippage: state.slippage.toString(),
    );

    if (swapCoinParameters == null) {
      return;
    }

    state = state.copyWith(
      isQuoteLoading: true,
      swapQuoteInfo: null,
    );

    final swapController = await ref.read(ionSwapClientProvider.future);
    try {
      final bscBalance = await _getBscBalance();
      final swapQuoteInfo = await swapController.getSwapQuote(
        swapCoinData: swapCoinParameters,
        bscBalance: bscBalance,
      );

      if (!isAmountValid(amount, swapQuoteInfo)) {
        final (minAmount: _, minAmountStr: minAmountStr) = _getMinAmountFromQuote(swapQuoteInfo);
        _setQuoteError(
          AmountBelowMinimumException(
            minAmount: minAmountStr,
            symbol: (state.sellCoin?.abbreviation ?? '').toUpperCase(),
          ),
        );
        return;
      }

      _setQuoteSuccess(swapQuoteInfo);
    } catch (e, stackTrace) {
      final mappedException = _mapSwapException(e);
      _setQuoteError(mappedException);

      if (e is! IonSwapException) {
        await SentryService.logException(
          e,
          stackTrace: stackTrace,
          tag: 'get_swap_quote_failure',
        );
      }
    }
  }

  Future<BigInt?> _getBscBalance() async {
    final walletView = await ref.read(currentWalletViewDataProvider.future);
    final coins = walletView.coins;
    final bscCoin = coins.firstWhereOrNull((coin) => coin.coin.native && coin.coin.network.isBsc);
    final rawAmount = bscCoin?.rawAmount;
    if (rawAmount == null) {
      return null;
    }

    return BigInt.parse(rawAmount);
  }

  Future<IonSwapRequest?> _buildIonSwapRequest(
    SwapCoinParameters swapCoinParameters,
    Wallet wallet,
    UserActionSignerNew userActionSigner,
  ) async {
    final isIonBscSwap = await getIsIonBscSwap();

    if (isIonBscSwap) {
      final identityClient = await ref.read(ionIdentityClientProvider.future);
      return IonSwapRequest(
        identityClient: identityClient,
        wallet: wallet,
        userActionSigner: userActionSigner,
      );
    }

    return null;
  }

  ({double? minAmount, String minAmountStr}) _getMinAmountFromQuote(SwapQuoteInfo quoteInfo) {
    return switch (quoteInfo.source) {
      SwapQuoteInfoSource.exolix when quoteInfo.exolixQuote != null => (
          minAmount: quoteInfo.exolixQuote!.minAmount.toDouble(),
          minAmountStr: quoteInfo.exolixQuote!.minAmount.toString(),
        ),
      SwapQuoteInfoSource.letsExchange when quoteInfo.letsExchangeQuote != null => (
          minAmount: double.tryParse(quoteInfo.letsExchangeQuote!.minAmount),
          minAmountStr: quoteInfo.letsExchangeQuote!.minAmount,
        ),
      _ => (minAmount: null, minAmountStr: '0'),
    };
  }

  bool isAmountValid(double amount, SwapQuoteInfo quoteInfo) {
    final (minAmount: minAmount, minAmountStr: _) = _getMinAmountFromQuote(quoteInfo);

    if (minAmount == null) {
      return true;
    }

    return amount >= minAmount;
  }

  void _setQuoteSuccess(SwapQuoteInfo quoteInfo) {
    state = state.copyWith(
      isQuoteLoading: false,
      swapQuoteInfo: quoteInfo,
      quoteError: null,
    );
  }

  void _setQuoteError(Exception error) {
    state = state.copyWith(
      isQuoteLoading: false,
      swapQuoteInfo: null,
      quoteError: error,
    );
  }

  Exception _mapSwapException(Object exception) {
    if (exception is ExolixBelowMinimumException) {
      return AmountBelowMinimumException(
        minAmount: exception.minAmount.toString(),
        symbol: (state.sellCoin?.abbreviation ?? '').toUpperCase(),
      );
    }

    return exception as Exception;
  }

  Future<bool> getIsIonBscSwap() async {
    final (:swapQuoteInfo, :swapCoinParameters, :sellNetwork, :sellCoin) = await _getData();

    final swapController = await ref.read(ionSwapClientProvider.future);
    return swapController.isIonBscSwap(swapCoinParameters);
  }

  Future<void> swapCoinsWithIonBscSwap({
    required UserActionSignerNew userActionSigner,
    required VoidCallback onSwapSuccess,
    required VoidCallback onSwapError,
    required VoidCallback onSwapStart,
  }) async {
    final swapController = await ref.read(ionSwapClientProvider.future);
    final (:swapQuoteInfo, :swapCoinParameters, :sellNetwork, :sellCoin) = await _getData();
    final sellAddress = swapCoinParameters.userSellAddress;

    if (sellAddress == null) {
      throw Exception('Sell address is required');
    }

    final walletView = await ref.read(walletViewByAddressProvider(sellAddress).future);

    final wallets = await ref.read(
      walletViewCryptoWalletsProvider(walletViewId: walletView?.id).future,
    );

    final senderWallet = wallets.firstWhereOrNull(
      (wallet) => wallet.network == sellNetwork.id,
    );

    if (senderWallet == null) {
      throw Exception('Sender wallet is required');
    }

    final ionSwapRequest = await _buildIonSwapRequest(
      swapCoinParameters,
      senderWallet,
      userActionSigner,
    );

    try {
      onSwapStart();

      await swapController.swapCoins(
        swapCoinData: swapCoinParameters,
        sendCoinCallback: ({required String depositAddress, required num amount}) async {
          // DO NOTHING HERE
        },
        swapQuoteInfo: swapQuoteInfo,
        ionSwapRequest: ionSwapRequest,
      );

      onSwapSuccess();
    } catch (e, stackTrace) {
      onSwapError();

      await SentryService.logException(
        e,
        stackTrace: stackTrace,
        tag: 'swap_coins_failure',
      );

      throw Exception(
        'Failed to swap coins: $e',
      );
    }
  }

  Future<
      ({
        SwapQuoteInfo? swapQuoteInfo,
        SwapCoinParameters swapCoinParameters,
        NetworkData sellNetwork,
        CoinInWalletData sellCoin,
      })> _getData() async {
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final sellCoinGroup = state.sellCoin;
    final buyCoinGroup = state.buyCoin;
    final amount = state.amount;
    final swapQuoteInfo = state.swapQuoteInfo;

    if (sellCoinGroup == null ||
        buyCoinGroup == null ||
        sellNetwork == null ||
        buyNetwork == null) {
      throw Exception('Sell coin group, buy coin group, sell network, buy network is required');
    }

    final sellCoin = await _getCoinWalletDataAndSyncIfNeeded(sellCoinGroup, sellNetwork);

    if (sellCoin == null) {
      throw Exception('Sell coin is required');
    }

    if (amount <= 0) {
      throw Exception('Amount is required');
    }

    final swapCoinParameters = await _buildSwapCoinParameters(
      sellCoinGroup: sellCoinGroup,
      sellNetwork: sellNetwork,
      buyCoinGroup: buyCoinGroup,
      buyNetwork: buyNetwork,
      amount: amount,
      slippage: state.slippage.toString(),
    );

    if (swapCoinParameters == null) {
      throw Exception('Swap coin parameters is required');
    }

    return (
      swapQuoteInfo: swapQuoteInfo,
      swapCoinParameters: swapCoinParameters,
      sellNetwork: sellNetwork,
      sellCoin: sellCoin,
    );
  }
}

@riverpod
class SwapCoinsWithIonBscSwap extends _$SwapCoinsWithIonBscSwap {
  @override
  FutureOr<void> build() {}

  Future<void> run({
    required UserActionSignerNew userActionSigner,
    required VoidCallback onSwapSuccess,
    required VoidCallback onSwapError,
    required VoidCallback onSwapStart,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(swapCoinsControllerProvider.notifier).swapCoinsWithIonBscSwap(
            userActionSigner: userActionSigner,
            onSwapSuccess: onSwapSuccess,
            onSwapError: onSwapError,
            onSwapStart: onSwapStart,
          );
    });
  }
}
