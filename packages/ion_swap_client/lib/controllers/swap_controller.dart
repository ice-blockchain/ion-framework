// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';

class SwapController {
  SwapController({
    required SwapOkxRepository swapOkxRepository,
    required RelayApiRepository relayApiRepository,
    required ChainsIdsRepository chainsIdsRepository,
    required ExolixRepository exolixRepository,
    required LetsExchangeRepository letsExchangeRepository,
  })  : _swapOkxRepository = swapOkxRepository,
        _chainsIdsRepository = chainsIdsRepository,
        _relayApiRepository = relayApiRepository,
        _exolixRepository = exolixRepository,
        _letsExchangeRepository = letsExchangeRepository;

  final SwapOkxRepository _swapOkxRepository;
  final RelayApiRepository _relayApiRepository;
  final ExolixRepository _exolixRepository;
  final LetsExchangeRepository _letsExchangeRepository;
  final ChainsIdsRepository _chainsIdsRepository;

  Future<void> swapCoins({
    required SwapCoinParameters swapCoinData,
  }) async {
    try {
      if (swapCoinData.isBridge) {
        await _tryToBridge(swapCoinData);
        return;
      }

      if (swapCoinData.sellNetworkId == swapCoinData.buyNetworkId) {
        await _tryToSwapOnSameNetwork(swapCoinData);
        // TODO(ice-erebus): implement CEX
        return;
      }
    } catch (e) {
      throw IonSwapException(
        'Failed to swap coins: $e',
      );
    }
  }

  // Returns true if swap was successful, false otherwise
  Future<bool> _tryToSwapOnSameNetwork(SwapCoinParameters swapCoinData) async {
    final okxChain = await _isOkxChainSupported(swapCoinData.sellCoinNetworkName);
    final sellTokenAddress = _getTokenAddress(swapCoinData.sellCoinContractAddress);
    final buyTokenAddress = _getTokenAddress(swapCoinData.buyCoinContractAddress);

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

  // TODO(ice-erebus): implement actual logic
  SwapQuoteData _pickBestOkxQuote(List<SwapQuoteData> quotes) {
    return quotes.first;
  }

  String _getTokenAddress(String contractAddress) {
    return contractAddress.isEmpty ? '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' : contractAddress;
  }

  T _processOkxResponse<T>(OkxApiResponse<T> response) {
    final responseCode = int.tryParse(response.code);
    if (responseCode == 0) {
      return response.data;
    }

    // TODO(ice-erebus): implement actual error handling
    throw Exception('Failed to process OKX response: $responseCode');
  }

  Future<void> _tryToBridge(SwapCoinParameters swapCoinData) async {
    await _relayApiRepository.getQuote();
  }
}
