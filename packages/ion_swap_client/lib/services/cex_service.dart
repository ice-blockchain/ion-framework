// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/lets_exchange_coin.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/services/swap_service.dart';

class CexService {
  CexService({
    required LetsExchangeRepository letsExchangeRepository,
    required ExolixRepository exolixRepository,
    required IONSwapConfig config,
  })  : _letsExchangeRepository = letsExchangeRepository,
        _exolixRepository = exolixRepository,
        _config = config;

  final LetsExchangeRepository _letsExchangeRepository;
  final ExolixRepository _exolixRepository;
  final IONSwapConfig _config;

  // TODO(ice-erebus): change logic here which API to use based on quotes
  Future<void> tryToCexSwap(
    SwapCoinParameters swapCoinData,
    SendCoinCallback sendCoinCallback,
  ) async {
    try {
      await _swapOnExolix(
        swapCoinData,
        sendCoinCallback,
      );
    } on Exception catch (_) {
      await _swapOnLetsExchange(swapCoinData, sendCoinCallback);
    }
  }

  Future<void> _swapOnLetsExchange(SwapCoinParameters swapCoinData, SendCoinCallback sendCoinCallback) async {
    final coins = await _letsExchangeRepository.getCoins();
    final activeCoins = coins.where((e) => e.isCoinActive);

    final sellCoin = activeCoins.firstWhereOrNull((e) => e.code == swapCoinData.sellCoinCode);
    final buyCoin = activeCoins.firstWhereOrNull((e) => e.code == swapCoinData.buyCoinCode);

    if (sellCoin == null || buyCoin == null) {
      throw const IonSwapException("Let's Exchnage: Coins pair not found");
    }

    final sellTokenAddress = _getTokenAddressForLetsExchange(
      swapCoinData.sellCoinContractAddress,
    );

    final sellNetwork = sellCoin.networks.firstWhereOrNull(
      (e) => e.contractAddress == sellTokenAddress,
    );

    final buyNetwork = buyCoin.networks.firstWhereOrNull(
      (e) => e.contractAddress == _getTokenAddressForLetsExchange(swapCoinData.buyCoinContractAddress),
    );

    if (sellNetwork == null || buyNetwork == null) {
      throw const IonSwapException("Let's Exchnage: Coins networks not found");
    }

    final rateInfo = await _letsExchangeRepository.getRates(
      from: sellCoin.code,
      to: buyCoin.code,
      networkFrom: sellNetwork.code,
      networkTo: buyNetwork.code,
      amount: swapCoinData.amount,
      affiliateId: _config.letsExchangeAffiliateId,
    );

    final transaction = await _letsExchangeRepository.createTransaction(
      coinFrom: sellCoin.code,
      coinTo: buyCoin.code,
      networkFrom: sellNetwork.code,
      networkTo: buyNetwork.code,
      depositAmount: swapCoinData.amount,
      withdrawalAddress: swapCoinData.userBuyAddress,
      affiliateId: _config.letsExchangeAffiliateId,
      rateId: rateInfo.rateId,
      withdrawalExtraId: swapCoinData.buyExtraId,
    );

    await sendCoinCallback(
      depositAddress: transaction.deposit,
      amount: num.parse(transaction.depositAmount),
    );
  }

  Future<void> _swapOnExolix(
    SwapCoinParameters swapCoinData,
    SendCoinCallback sendCoinCallback,
  ) async {
    final sellCoins = await _exolixRepository.getCoins(
      coinCode: swapCoinData.sellCoinCode,
    );

    final buyCoins = await _exolixRepository.getCoins(
      coinCode: swapCoinData.buyCoinCode,
    );

    final sellCoin = sellCoins.firstWhereOrNull((e) => e.code.toLowerCase() == swapCoinData.sellCoinCode.toLowerCase());
    final buyCoin = buyCoins.firstWhereOrNull((e) => e.code.toLowerCase() == swapCoinData.buyCoinCode.toLowerCase());

    if (sellCoin == null || buyCoin == null) {
      throw const IonSwapException('Exolix: Coins pair not found');
    }

    final sellNetwork = sellCoin.networks
        .firstWhereOrNull((e) => e.name.toLowerCase() == swapCoinData.sellCoinNetworkName.toLowerCase());
    final buyNetwork =
        buyCoin.networks.firstWhereOrNull((e) => e.name.toLowerCase() == swapCoinData.buyCoinNetworkName.toLowerCase());

    if (sellNetwork == null || buyNetwork == null) {
      throw const IonSwapException('Exolix: Coins networks not found');
    }

    await _exolixRepository.getRates(
      coinFrom: sellCoin.code,
      networkFrom: sellNetwork.network,
      coinTo: buyCoin.code,
      networkTo: buyNetwork.network,
      amount: swapCoinData.amount,
    );

    final transaction = await _exolixRepository.createTransaction(
      coinFrom: sellCoin.code,
      networkFrom: sellNetwork.network,
      coinTo: buyCoin.code,
      networkTo: buyNetwork.network,
      amount: swapCoinData.amount,
      withdrawalAddress: swapCoinData.userBuyAddress,
      withdrawalExtraId: swapCoinData.buyExtraId.isNotEmpty ? swapCoinData.buyExtraId : null,
    );

    await sendCoinCallback(
      depositAddress: transaction.depositAddress,
      amount: transaction.amount,
    );
  }

  String? _getTokenAddressForLetsExchange(String contractAddress) {
    return contractAddress.isEmpty ? null : contractAddress;
  }
}
