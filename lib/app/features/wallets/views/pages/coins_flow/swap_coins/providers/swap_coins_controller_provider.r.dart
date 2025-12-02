// SPDX-License-Identifier: ice License 1.0

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
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/services/ion_swap_client/ion_swap_client_provider.r.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_coins_controller_provider.r.g.dart';

typedef OnVerifyIdentitySwapCallback = Future<void> Function(SendAssetFormData);

@Riverpod(keepAlive: true)
class SwapCoinsController extends _$SwapCoinsController {
  @override
  SwapCoinData build() => const SwapCoinData();

  void initSellCoin({
    required CoinsGroup? coin,
    required NetworkData? network,
  }) =>
      state = state.copyWith(
        sellCoin: coin,
        sellNetwork: network,
        buyCoin: null,
        buyNetwork: null,
      );

  void setSellCoin(CoinsGroup coin) => state = state.copyWith(
        sellCoin: coin,
      );

  void setSellNetwork(NetworkData network) => state = state.copyWith(
        sellNetwork: network,
      );

  void setBuyCoin(CoinsGroup coin) => state = state.copyWith(
        buyCoin: coin,
      );

  void setBuyNetwork(NetworkData network) => state = state.copyWith(
        buyNetwork: network,
      );

  void switchCoins() {
    final sellCoin = state.sellCoin;
    final buyCoin = state.buyCoin;
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;

    state = state.copyWith(
      sellCoin: buyCoin,
      buyCoin: sellCoin,
      sellNetwork: buyNetwork,
      buyNetwork: sellNetwork,
    );
  }

  Future<({CoinsGroup? coin, NetworkData? network})> selectCoin({
    required CoinSwapType type,
    required CoinsGroup coin,
    required Future<NetworkData?> Function() selectNetworkRouteLocationBuilder,
  }) async {
    switch (type) {
      case CoinSwapType.sell:
        setSellCoin(coin);
      case CoinSwapType.buy:
        setBuyCoin(coin);
    }

    final result = await selectNetworkRouteLocationBuilder();
    if (result != null) {
      switch (type) {
        case CoinSwapType.sell:
          setSellNetwork(result);
        case CoinSwapType.buy:
          setBuyNetwork(result);
      }
    }

    return (
      coin: state.sellCoin,
      network: state.sellNetwork,
    );
  }

  Future<void> swapCoins({
    required String userSellAddress,
    required String userBuyAddress,
    required OnVerifyIdentitySwapCallback onVerifyIdentitySwapCallback,
    required VoidCallback onSwapSuccess,
    required VoidCallback onSwapError,
  }) async {
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final sellCoinGroup = state.sellCoin;
    final buyCoinGroup = state.buyCoin;

    if (sellCoinGroup == null || buyCoinGroup == null || sellNetwork == null || buyNetwork == null) {
      return;
    }

    final sellCoin = sellCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == sellNetwork.id);
    final buyCoin = buyCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == buyNetwork.id);

    if (sellCoin == null || buyCoin == null) {
      return;
    }

    try {
      final swapController = await ref.read(ionSwapClientProvider.future);
      await swapController.swapCoins(
        // TODO(ice-erebus): actual data
        swapCoinData: SwapCoinParameters(
          isBridge: buyCoinGroup == sellCoinGroup,
          amount: '0.1',
          buyCoinContractAddress: buyCoin.coin.contractAddress,
          sellCoinContractAddress: sellCoin.coin.contractAddress,
          buyCoinNetworkName: buyNetwork.displayName,
          sellCoinNetworkName: sellNetwork.displayName,
          buyNetworkId: buyNetwork.id,
          sellNetworkId: sellNetwork.id,
          userBuyAddress: userBuyAddress,
          userSellAddress: userSellAddress,
          buyCoinCode: buyCoin.coin.abbreviation,
          sellCoinCode: sellCoin.coin.abbreviation,

          /// it's extra id used for some coins
          /// since ion provides only personal wallets for use it's fixed
          buyExtraId: buyNetwork.isMemoSupported ? 'Online' : '',
        ),
        sendCoinCallback: ({
          required String depositAddress,
          required num amount,
        }) async {
          try {
            await _sendCoinCallback(
              depositAddress: depositAddress,
              amount: amount,
              onVerifyIdentitySwapCallback: onVerifyIdentitySwapCallback,
              memo: sellNetwork.isMemoSupported ? 'Online' : null,
              sellAddress: userSellAddress,
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
}
