// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
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
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_form_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SendAssetFormController extends _$SendAssetFormController {
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

  Future<void> setNetwork(NetworkData network) async {
    final wallets = await ref.read(
      walletViewCryptoWalletsProvider(walletViewId: state.walletView?.id).future,
    );

    // Reset current information about network
    state = state.copyWith(
      network: network,
      senderWallet: wallets.firstWhereOrNull(
        (wallet) => wallet.network == network.id,
      ),
      networkFeeOptions: [],
      selectedNetworkFeeOption: null,
    );

    unawaited(
      _initReceiverAddressFromContact(),
    );

    if (state.assetData case final CoinAssetToSendData coin) {
      var selectedOption = coin.coinsGroup.coins.firstWhereOrNull(
        (e) => e.coin.network == network,
      );

      if (selectedOption == null) {
        final coinData = await (await ref.watch(coinsServiceProvider.future))
            .getCoinsByFilters(
              network: network,
              symbol: coin.coinsGroup.abbreviation,
              symbolGroup: coin.coinsGroup.symbolGroup,
            )
            .then((coins) => coins.firstOrNull);
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
        assetData: coin.copyWith(
          selectedOption: selectedOption,
        ),
        senderWallet: isCryptoWalletCorrect
            ? state.senderWallet
            : wallets.firstWhereOrNull((w) => w.id == selectedOption!.walletId),
      );

      final networkFeeInfo = await ref.read(
        networkFeeProvider(
          walletId: state.senderWallet?.id,
          network: state.network!,
          transferredCoin: selectedOption?.coin,
        ).future,
      );

      if (networkFeeInfo != null) {
        state = state.copyWith(
          networkFeeOptions: networkFeeInfo.networkFeeOptions,
          selectedNetworkFeeOption: networkFeeInfo.networkFeeOptions.firstOrNull,
          networkNativeToken: networkFeeInfo.networkNativeToken,
          assetData: coin.copyWith(
            associatedAssetWithSelectedOption: networkFeeInfo.sendableAsset,
            selectedOption: selectedOption,
          ),
        );
        _checkIfUserCanCoverFee(coin);
      }
    }
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

      state = state.copyWith(
        assetData: updatedCoin,
        exceedsMaxAmount: false,
      );
      _checkIfUserCanCoverFee(updatedCoin);
    }
  }

  void setReceiverAddress(String address) {
    state = state.copyWith(receiverAddress: address);
  }

  void selectNetworkFeeOption(NetworkFeeOption selectedOption) {
    state = state.copyWith(
      selectedNetworkFeeOption: selectedOption,
    );

    if (state.assetData case final CoinAssetToSendData coin) {
      _checkIfUserCanCoverFee(coin);
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
}
