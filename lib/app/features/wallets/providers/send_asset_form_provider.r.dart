// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/model/send_asset_form_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/connected_crypto_wallets_provider.r.dart';
import 'package:ion/app/features/wallets/providers/network_fee_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/wallet_asset_utils.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_form_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SendAssetFormController extends _$SendAssetFormController {
  CancelableOperation<void>? _receiverAddressOperation;

  @override
  SendAssetFormData build() {
    return SendAssetFormData(
      arrivalDateTime: DateTime.now().microsecondsSinceEpoch,
      receiverAddress: '',
      assetData: const CryptoAssetToSendData.notInitialized(),
    );
  }

  void setWalletView(WalletViewData walletView) {
    state = state.copyWith(walletView: walletView);
  }

  Future<void> setCoin(CoinsGroup coin, [WalletViewData? walletView]) async {
    state = state.copyWith(
      assetData: CryptoAssetToSendData.coin(coinsGroup: coin),
      senderWallet: null,
      walletView: walletView ?? await ref.read(currentWalletViewDataProvider.future),
      networkFeeOptions: [],
      selectedNetworkFeeOption: null,
    );
  }

  void setContact(String? pubkey, {bool isContactPreselected = false}) {
    state = state.copyWith(contactPubkey: pubkey, isContactPreselected: isContactPreselected);
    _initReceiverAddressFromContact();
  }

  Future<void> _initReceiverAddressFromContact() async {
    final network = state.network;
    final pubkey = state.contactPubkey;

    if (pubkey != null && network != null) {
      final contactMetadata = await ref.read(userMetadataProvider(pubkey, cache: false).future);
      final walletAddress = contactMetadata?.data.wallets?[network.id];

      // Assuming that wallet address shouldn't be null because of the check during selection
      if (walletAddress != null) {
        state = state.copyWith(receiverAddress: walletAddress);
      }
    }
  }

  void _resetNetworkState({
    required NetworkData network,
    required ion.Wallet? senderWallet,
  }) {
    _receiverAddressOperation?.cancel();

    state = state.copyWith(
      network: network,
      senderWallet: senderWallet,
      networkFeeOptions: [],
      selectedNetworkFeeOption: null,
    );

    _receiverAddressOperation = CancelableOperation.fromFuture(
      _initReceiverAddressFromContact(),
    );
  }

  Future<CoinData?> _findCoinDataForNetwork({
    required NetworkData network,
    required CoinAssetToSendData coin,
  }) async {
    final existingOption = coin.coinsGroup.coins.firstWhereOrNull(
      (e) => e.coin.network == network,
    );

    return existingOption?.coin ??
        await _getCoinDataForNetwork(
          network: network,
          symbolGroup: coin.coinsGroup.symbolGroup,
          abbreviation: coin.coinsGroup.abbreviation,
        );
  }

  Future<void> _updateNetworkFeeState({
    required CoinAssetToSendData coin,
    required CoinInWalletData selectedOption,
    required String? walletId,
    required NetworkData network,
    required CoinData coinData,
  }) async {
    final networkFeeInfo = await ref.read(
      networkFeeProvider(
        walletId: walletId,
        network: network,
        transferredCoin: coinData,
      ).future,
    );

    if (networkFeeInfo != null) {
      final updatedCoin = coin.copyWith(
        associatedAssetWithSelectedOption: networkFeeInfo.sendableAsset,
        selectedOption: selectedOption,
      );

      state = state.copyWith(
        networkFeeOptions: networkFeeInfo.networkFeeOptions,
        selectedNetworkFeeOption: networkFeeInfo.networkFeeOptions.firstOrNull,
        networkNativeToken: networkFeeInfo.networkNativeToken,
      );

      _updateCoinAssetWithMaxAmount(updatedCoin);
    }
  }

  Future<void> setNetwork(NetworkData network) async {
    final wallets = await ref.read(
      walletViewCryptoWalletsProvider(walletViewId: state.walletView?.id).future,
    );

    final initialWallet = wallets.firstWhereOrNull(
      (wallet) => wallet.network == network.id,
    );

    _resetNetworkState(network: network, senderWallet: initialWallet);

    if (state.assetData case final CoinAssetToSendData coin) {
      var selectedOption = coin.coinsGroup.coins.firstWhereOrNull(
        (e) => e.coin.network == network,
      );

      if (selectedOption == null) {
        final coinData = await _findCoinDataForNetwork(network: network, coin: coin);

        if (coinData != null) {
          selectedOption = CoinInWalletData(coin: coinData);
        }
      }

      // We should check the case, when user has several crypto wallets in one network.
      // So, if we initially selected a wallet that doesn't have the same id
      // as the selected coin wallet, we must correct this.
      final isCryptoWalletCorrect =
          selectedOption?.walletId != null && selectedOption?.walletId == state.senderWallet?.id;

      state = state.copyWith(
        assetData: coin.copyWith(selectedOption: selectedOption),
        senderWallet: isCryptoWalletCorrect || selectedOption == null
            ? state.senderWallet
            : wallets.firstWhereOrNull((w) => w.id == selectedOption!.walletId),
      );

      if (selectedOption != null) {
        await _updateNetworkFeeState(
          coin: coin,
          selectedOption: selectedOption,
          walletId: state.senderWallet?.id,
          network: network,
          coinData: selectedOption.coin,
        );
      }
    }
  }

  Future<void> setNetworkWithWallet(NetworkData network, ion.Wallet wallet) async {
    _resetNetworkState(network: network, senderWallet: wallet);

    if (state.assetData case final CoinAssetToSendData coin) {
      final coinData = await _findCoinDataForNetwork(network: network, coin: coin);

      if (coinData == null) return;

      final client = await ref.read(ionIdentityClientProvider.future);
      final walletAssets = await client.wallets.getWalletAssets(wallet.id);
      final asset = getAssociatedWalletAsset(walletAssets.assets, coinData);

      final balance = asset != null
          ? calculateBalanceFromAsset(asset, coinData)
          : (amount: 0.0, balanceUSD: 0.0, rawAmount: '0');

      final selectedOption = CoinInWalletData(
        coin: coinData,
        amount: balance.amount,
        balanceUSD: balance.balanceUSD,
        rawAmount: balance.rawAmount,
        walletId: wallet.id,
      );

      state = state.copyWith(
        assetData: coin.copyWith(selectedOption: selectedOption),
      );

      await _updateNetworkFeeState(
        coin: coin,
        selectedOption: selectedOption,
        walletId: wallet.id,
        network: network,
        coinData: coinData,
      );
    }
  }

  Future<CoinData?> _getCoinDataForNetwork({
    required NetworkData network,
    required String symbolGroup,
    required String abbreviation,
  }) async {
    final coins = await (await ref.read(coinsServiceProvider.future)).getCoinsByFilters(
      network: network,
      symbolGroup: symbolGroup,
    );
    return coins.firstWhereOrNull((e) => e.abbreviation == abbreviation) ?? coins.firstOrNull;
  }

  void _checkIfUserCanCoverFee(CoinAssetToSendData coin) {
    final isSendingNativeToken = coin.selectedOption?.coin.native ?? false;
    final canCover = canUserCoverFee(
      sendAmount: coin.amount,
      isSendingNativeToken: isSendingNativeToken,
      selectedFee: state.selectedNetworkFeeOption,
      networkNativeToken: state.networkNativeToken,
    );
    state = state.copyWith(canCoverNetworkFee: canCover);
  }

  void setCoinsAmount(String amount) {
    if (state.assetData case final CoinAssetToSendData coin) {
      final parsedAmount = parseAmount(amount) ?? 0.0;
      final updatedCoin = coin.copyWith(
        amount: parsedAmount,
        amountUSD: parsedAmount * (coin.selectedOption?.coin.priceUSD ?? 0),
      );

      state = state.copyWith(exceedsMaxAmount: false);
      _updateCoinAssetWithMaxAmount(updatedCoin);
    }
  }

  void setReceiverAddress(String address) {
    state = state.copyWith(receiverAddress: address);
  }

  void selectNetworkFeeOption(NetworkFeeOption selectedOption) {
    state = state.copyWith(selectedNetworkFeeOption: selectedOption);

    if (state.assetData case final CoinAssetToSendData coin) {
      _updateCoinAssetWithMaxAmount(coin);
    }
  }

  void setRequest(FundsRequestEntity request) {
    state = state.copyWith(request: request);
  }

  set exceedsMaxAmount(bool value) {
    state = state.copyWith(exceedsMaxAmount: value);
  }

  void setMemo(String memo) {
    state = state.copyWith(memo: memo);
  }

  void _updateCoinAssetWithMaxAmount(CoinAssetToSendData coin) {
    final maxAmountToSend = _calculateMaxAmountToSend(coin);
    final updatedCoin = coin.copyWith(maxAmountToSend: maxAmountToSend);

    state = state.copyWith(assetData: updatedCoin);
    _checkIfUserCanCoverFee(updatedCoin);
  }

  double _calculateMaxAmountToSend(CoinAssetToSendData coin) {
    final selectedOption = coin.selectedOption;
    final selectedFee = state.selectedNetworkFeeOption;

    if (selectedOption == null) return 0;

    final availableBalance = selectedOption.amount;
    final feeAmount = selectedFee?.amount ?? 0;
    final isSendingNativeToken = selectedOption.coin.native;

    if (isSendingNativeToken) {
      final maxAmount = availableBalance - feeAmount;
      return maxAmount > 0 ? maxAmount : availableBalance;
    } else {
      return availableBalance;
    }
  }
}
