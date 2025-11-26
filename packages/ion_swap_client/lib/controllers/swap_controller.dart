// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/lets_exchange_coin.m.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';

typedef SendCoinCallback = Future<void> Function({
  required String depositAddress,
  required num amount,
});

class SwapController {
  SwapController({
    required SwapOkxRepository swapOkxRepository,
    required RelayApiRepository relayApiRepository,
    required ChainsIdsRepository chainsIdsRepository,
    required ExolixRepository exolixRepository,
    required LetsExchangeRepository letsExchangeRepository,
    required IONSwapConfig config,
  })  : _swapOkxRepository = swapOkxRepository,
        _chainsIdsRepository = chainsIdsRepository,
        _relayApiRepository = relayApiRepository,
        _exolixRepository = exolixRepository,
        _letsExchangeRepository = letsExchangeRepository,
        _config = config;

  final SwapOkxRepository _swapOkxRepository;
  final RelayApiRepository _relayApiRepository;
  final ExolixRepository _exolixRepository;
  final LetsExchangeRepository _letsExchangeRepository;
  final ChainsIdsRepository _chainsIdsRepository;
  final IONSwapConfig _config;

  Future<void> swapCoins({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
  }) async {
    try {
      await _tryToCexSwap(
        swapCoinData,
        sendCoinCallback,
      );
      return;
      if (swapCoinData.isBridge) {
        await _tryToBridge(swapCoinData);
        return;
      }

      if (swapCoinData.sellNetworkId == swapCoinData.buyNetworkId) {
        final success = await _tryToSwapOnSameNetwork(swapCoinData);
        if (success) {
          return;
        }
      }

      await _tryToCexSwap(
        swapCoinData,
        sendCoinCallback,
      );
    } catch (e) {
      throw IonSwapException(
        'Failed to swap coins: $e',
      );
    }
  }

  // Returns true if swap was successful, false otherwise
  Future<bool> _tryToSwapOnSameNetwork(SwapCoinParameters swapCoinData) async {
    final okxChain = await _isOkxChainSupported(swapCoinData.sellCoinNetworkName);
    final sellTokenAddress = _getTokenAddressForOkx(swapCoinData.sellCoinContractAddress);
    final buyTokenAddress = _getTokenAddressForOkx(swapCoinData.buyCoinContractAddress);

    if (okxChain != null) {
      final quotesResponse = await _swapOkxRepository.getQuotes(
        chainIndex: okxChain.chainIndex,
        amount: swapCoinData.amount,
        fromTokenAddress: sellTokenAddress,
        toTokenAddress: buyTokenAddress,
      );

      final quotes = _processOkxResponse(quotesResponse);

      if (quotes.isNotEmpty) {
        final quote = _pickBestOkxQuote(quotes);

        await _swapOkxRepository.approveTransaction(
          chainIndex: quote.chainIndex,
          tokenContractAddress: sellTokenAddress,
          amount: swapCoinData.amount,
        );

        await _swapOkxRepository.swap(
          chainIndex: quote.chainIndex,
          amount: swapCoinData.amount,
          toTokenAddress: buyTokenAddress,
          fromTokenAddress: sellTokenAddress,
          userWalletAddress: swapCoinData.userSellAddress,
        );

        await _swapOkxRepository.simulateSwap();

        return true;
      }
    }

    return false;
  }

  Future<SwapChainData?> _isOkxChainSupported(String networkName) async {
    final supportedChainsIds = await _chainsIdsRepository.getOkxChainsIds();
    final chainOkxIndex = supportedChainsIds.firstWhereOrNull(
      (chain) => chain.name.toLowerCase() == networkName.toLowerCase(),
    );

    final supportedChainsResponse = await _swapOkxRepository.getSupportedChains();
    final supportedChains = _processOkxResponse(supportedChainsResponse);
    final supportedChain = supportedChains.firstWhereOrNull(
      (chain) => chain.chainIndex == chainOkxIndex?.networkId,
    );

    return supportedChain;
  }

  // TODO(ice-erebus): implement actual logic (this one in PR with UI)
  SwapQuoteData _pickBestOkxQuote(List<SwapQuoteData> quotes) {
    return quotes.first;
  }

  String _getTokenAddressForOkx(String contractAddress) {
    return contractAddress.isEmpty ? '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' : contractAddress;
  }

  String? _getTokenAddressForLetsExchange(String contractAddress) {
    return contractAddress.isEmpty ? null : contractAddress;
  }

  T _processOkxResponse<T>(OkxApiResponse<T> response) {
    final responseCode = int.tryParse(response.code);
    if (responseCode == 0) {
      return response.data;
    }

    throw Exception('Failed to process OKX response: $responseCode');
  }

  Future<void> _tryToBridge(SwapCoinParameters swapCoinData) async {
    await _relayApiRepository.getQuote();
  }

  Future<void> _tryToCexSwap(
    SwapCoinParameters swapCoinData,
    SendCoinCallback sendCoinCallback,
  ) async {
    try {
      await _swapOnExolix(
        swapCoinData,
        sendCoinCallback,
      );
    } catch (e) {
      await _swapOnLetsExchange(swapCoinData);
    }
  }

  Future<void> _swapOnLetsExchange(SwapCoinParameters swapCoinData) async {
    final coins = await _letsExchangeRepository.getCoins();
    final activeCoins = coins.where((e) => e.isCoinActive);

    final sellCoin = activeCoins.firstWhereOrNull((e) => e.code == swapCoinData.sellCoinCode);
    final buyCoin = activeCoins.firstWhereOrNull((e) => e.code == swapCoinData.buyCoinCode);

    if (sellCoin == null || buyCoin == null) {
      throw Exception("Let's Exchnage: Coins pair not found");
    }

    final sellNetwork = sellCoin.networks.firstWhereOrNull(
      (e) =>
          e.contractAddress ==
          _getTokenAddressForLetsExchange(
            swapCoinData.sellCoinContractAddress,
          ),
    );

    final buyNetwork = buyCoin.networks.firstWhereOrNull(
      (e) => e.contractAddress == _getTokenAddressForLetsExchange(swapCoinData.buyCoinContractAddress),
    );

    if (sellNetwork == null || buyNetwork == null) {
      throw Exception("Let's Exchnage: Coins networks not found");
    }

    final rateInfo = await _letsExchangeRepository.getRates(
      from: sellCoin.code,
      to: buyCoin.code,
      networkFrom: sellNetwork.code,
      networkTo: buyNetwork.code,
      amount: swapCoinData.amount,
      affiliateId: _config.letsExchangeAffiliateId,
    );

    await _letsExchangeRepository.createTransaction(
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

    final sellCoin = sellCoins.firstWhereOrNull((e) => e.code == swapCoinData.sellCoinCode);
    final buyCoin = buyCoins.firstWhereOrNull((e) => e.code == swapCoinData.buyCoinCode);

    if (sellCoin == null || buyCoin == null) {
      throw Exception('Exolix: Coins pair not found');
    }

    final sellNetwork = sellCoin.networks.firstWhereOrNull((e) => e.name == swapCoinData.sellCoinNetworkName);
    final buyNetwork = buyCoin.networks.firstWhereOrNull((e) => e.name == swapCoinData.buyCoinNetworkName);

    if (sellNetwork == null || buyNetwork == null) {
      throw Exception('Exolix: Coins networks not found');
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
}
