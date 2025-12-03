// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/exolix_coin.m.dart';
import 'package:ion_swap_client/models/exolix_network.m.dart';
import 'package:ion_swap_client/models/exolix_rate.m.dart';
import 'package:ion_swap_client/models/lets_exchange_coin.m.dart';
import 'package:ion_swap_client/models/lets_exchange_info.m.dart';
import 'package:ion_swap_client/models/lets_exchange_network.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
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

  Future<void> tryToCexSwap({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
    required SwapQuoteInfo swapQuoteInfo,
  }) async {
    try {
      if (swapQuoteInfo.source == SwapQuoteInfoSource.exolix) {
        final exolixRate = swapQuoteInfo.exolixQuote;
        if (exolixRate == null) {
          throw const IonSwapException('Exolix: Rate is required');
        }

        await _swapOnExolix(
          swapCoinData,
          sendCoinCallback,
          exolixRate,
        );
      } else if (swapQuoteInfo.source == SwapQuoteInfoSource.letsExchange) {
        final letsExchangeInfo = swapQuoteInfo.letsExchangeQuote;
        if (letsExchangeInfo == null) {
          throw const IonSwapException('Lets Exchange: Rate is required');
        }

        await _swapOnLetsExchange(
          swapCoinData,
          sendCoinCallback,
          letsExchangeInfo,
        );
      } else {
        throw const IonSwapException('Failed to swap on Cex: Invalid quote source');
      }
    } on Exception catch (e) {
      throw IonSwapException('Failed to swap on Cex: $e');
    }
  }

  Future<SwapQuoteInfo> getCexSwapQuote(
    SwapCoinParameters swapCoinData,
  ) async {
    final (
      sellCoinExolix,
      buyCoinExolix,
      sellNetworkExolix,
      buyNetworkExolix,
    ) = await _getSwapDataExolix(swapCoinData: swapCoinData);

    final exolixRate = await _getQuoteOnExolix(
      swapCoinData: swapCoinData,
      sellCoin: sellCoinExolix,
      sellNetwork: sellNetworkExolix,
      buyCoin: buyCoinExolix,
      buyNetwork: buyNetworkExolix,
    );

    final (
      sellCoinLetsExchange,
      buyCoinLetsExchange,
      sellNetworkLetsExchange,
      buyNetworkLetsExchange,
    ) = await _getSwapDataLetsExchange(swapCoinData: swapCoinData);

    final letsExchangeRate = await _getQuoteOnLetsExchange(
      swapCoinData: swapCoinData,
      sellCoin: sellCoinLetsExchange,
      buyCoin: buyCoinLetsExchange,
      sellNetwork: sellNetworkLetsExchange,
      buyNetwork: buyNetworkLetsExchange,
    );

    if (exolixRate == null && letsExchangeRate == null) {
      throw const IonSwapException('Failed to get quote on Cex: No quote found');
    } else if (exolixRate != null && letsExchangeRate != null) {
      final exolixRateDouble = exolixRate.rate.toDouble();

      final letsExchangeRateDouble = num.parse(letsExchangeRate.rate).toDouble();
      if (exolixRateDouble > letsExchangeRateDouble) {
        return SwapQuoteInfo(
          type: SwapQuoteInfoType.cexOrDex,
          priceForSellTokenInBuyToken: exolixRateDouble,
          source: SwapQuoteInfoSource.exolix,
          exolixQuote: exolixRate,
        );
      }

      return SwapQuoteInfo(
        type: SwapQuoteInfoType.cexOrDex,
        priceForSellTokenInBuyToken: letsExchangeRateDouble,
        source: SwapQuoteInfoSource.letsExchange,
        letsExchangeQuote: letsExchangeRate,
      );
    } else if (exolixRate != null) {
      final exolixRateDouble = exolixRate.rate.toDouble();

      return SwapQuoteInfo(
        type: SwapQuoteInfoType.cexOrDex,
        priceForSellTokenInBuyToken: exolixRateDouble,
        source: SwapQuoteInfoSource.exolix,
        exolixQuote: exolixRate,
      );
    } else if (letsExchangeRate != null) {
      final letsExchangeRateDouble = num.parse(letsExchangeRate.rate).toDouble();

      return SwapQuoteInfo(
        type: SwapQuoteInfoType.cexOrDex,
        priceForSellTokenInBuyToken: letsExchangeRateDouble,
        source: SwapQuoteInfoSource.letsExchange,
        letsExchangeQuote: letsExchangeRate,
      );
    }

    throw const IonSwapException('Failed to get quote on Cex: No quote found');
  }

  Future<void> _swapOnLetsExchange(
    SwapCoinParameters swapCoinData,
    SendCoinCallback sendCoinCallback,
    LetsExchangeInfo letsExchangeInfo,
  ) async {
    final withdrawalAddress = swapCoinData.userBuyAddress;
    if (withdrawalAddress == null) {
      throw const IonSwapException('Lets Exchange: Withdrawal address is required');
    }

    final (sellCoin, buyCoin, sellNetwork, buyNetwork) =
        await _getSwapDataLetsExchange(swapCoinData: swapCoinData);

    final transaction = await _letsExchangeRepository.createTransaction(
      coinFrom: sellCoin.code,
      coinTo: buyCoin.code,
      networkFrom: sellNetwork.code,
      networkTo: buyNetwork.code,
      depositAmount: swapCoinData.amount,
      withdrawalAddress: withdrawalAddress,
      affiliateId: _config.letsExchangeAffiliateId,
      rateId: letsExchangeInfo.rateId,
      withdrawalExtraId: swapCoinData.buyExtraId,
    );

    await sendCoinCallback(
      depositAddress: transaction.deposit,
      amount: num.parse(transaction.depositAmount),
    );
  }

  Future<LetsExchangeInfo?> _getQuoteOnLetsExchange({
    required SwapCoinParameters swapCoinData,
    required LetsExchangeCoin sellCoin,
    required LetsExchangeCoin buyCoin,
    required LetsExchangeNetwork sellNetwork,
    required LetsExchangeNetwork buyNetwork,
  }) async {
    try {
      final rateInfo = await _letsExchangeRepository.getRates(
        from: sellCoin.code,
        to: buyCoin.code,
        networkFrom: sellNetwork.code,
        networkTo: buyNetwork.code,
        amount: swapCoinData.amount,
        affiliateId: _config.letsExchangeAffiliateId,
      );

      return rateInfo;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> _swapOnExolix(
    SwapCoinParameters swapCoinData,
    SendCoinCallback sendCoinCallback,
    ExolixRate exolixRate,
  ) async {
    final (sellCoin, buyCoin, sellNetwork, buyNetwork) =
        await _getSwapDataExolix(swapCoinData: swapCoinData);

    final withdrawalAddress = swapCoinData.userBuyAddress;

    if (withdrawalAddress == null) {
      throw const IonSwapException('Exolix: Withdrawal address is required');
    }

    final transaction = await _exolixRepository.createTransaction(
      coinFrom: sellCoin.code,
      networkFrom: sellNetwork.network,
      coinTo: buyCoin.code,
      networkTo: buyNetwork.network,
      amount: swapCoinData.amount,
      withdrawalAddress: withdrawalAddress,
      withdrawalExtraId: swapCoinData.buyExtraId.isNotEmpty ? swapCoinData.buyExtraId : null,
    );

    await sendCoinCallback(
      depositAddress: transaction.depositAddress,
      amount: transaction.amount,
    );
  }

  Future<ExolixRate?> _getQuoteOnExolix({
    required SwapCoinParameters swapCoinData,
    required ExolixCoin sellCoin,
    required ExolixNetwork sellNetwork,
    required ExolixCoin buyCoin,
    required ExolixNetwork buyNetwork,
  }) async {
    try {
      final rate = await _exolixRepository.getRates(
        coinFrom: sellCoin.code,
        networkFrom: sellNetwork.network,
        coinTo: buyCoin.code,
        networkTo: buyNetwork.network,
        amount: swapCoinData.amount,
      );

      return rate;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<(ExolixCoin, ExolixCoin, ExolixNetwork, ExolixNetwork)> _getSwapDataExolix({
    required SwapCoinParameters swapCoinData,
  }) async {
    final sellCoins = await _exolixRepository.getCoins(
      coinCode: swapCoinData.sellCoinCode,
    );

    final buyCoins = await _exolixRepository.getCoins(
      coinCode: swapCoinData.buyCoinCode,
    );

    final sellCoin = sellCoins
        .firstWhereOrNull((e) => e.code.toLowerCase() == swapCoinData.sellCoinCode.toLowerCase());
    final buyCoin = buyCoins
        .firstWhereOrNull((e) => e.code.toLowerCase() == swapCoinData.buyCoinCode.toLowerCase());

    if (sellCoin == null || buyCoin == null) {
      throw const IonSwapException('Exolix: Coins pair not found');
    }

    final sellNetwork = sellCoin.networks.firstWhereOrNull(
      (e) => e.name.toLowerCase() == swapCoinData.sellCoinNetworkName.toLowerCase(),
    );
    final buyNetwork = buyCoin.networks.firstWhereOrNull(
      (e) => e.name.toLowerCase() == swapCoinData.buyCoinNetworkName.toLowerCase(),
    );

    if (sellNetwork == null || buyNetwork == null) {
      throw const IonSwapException('Exolix: Coins networks not found');
    }

    return (sellCoin, buyCoin, sellNetwork, buyNetwork);
  }

  Future<(LetsExchangeCoin, LetsExchangeCoin, LetsExchangeNetwork, LetsExchangeNetwork)>
      _getSwapDataLetsExchange({
    required SwapCoinParameters swapCoinData,
  }) async {
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
      (e) =>
          e.contractAddress == _getTokenAddressForLetsExchange(swapCoinData.buyCoinContractAddress),
    );

    if (sellNetwork == null || buyNetwork == null) {
      throw const IonSwapException("Let's Exchnage: Coins networks not found");
    }

    return (sellCoin, buyCoin, sellNetwork, buyNetwork);
  }

  String? _getTokenAddressForLetsExchange(String contractAddress) {
    return contractAddress.isEmpty ? null : contractAddress;
  }
}
