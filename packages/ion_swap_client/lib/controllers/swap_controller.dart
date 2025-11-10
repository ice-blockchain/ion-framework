// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';

class SwapController {
  SwapController({
    required SwapOkxRepository swapOkxRepository,
  }) : _swapOkxRepository = swapOkxRepository;

  final SwapOkxRepository _swapOkxRepository;

  Future<void> swapCoins({
    required SwapCoinParameters swapCoinData,
  }) async {
    if (swapCoinData.sellNetworkId == swapCoinData.buyNetworkId) {
      final result = await _tryToSwapOnSameNetwork(swapCoinData);

      // TODO(ice-erebus): implement bridge and CEX
      if (result) {
        return;
      }
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
    final supportedChainsIds = await _swapOkxRepository.getSupportedChainsIds();
    final chainOkxIndex = supportedChainsIds.firstWhereOrNull(
      (chain) => chain.keys.first.toLowerCase() == networkName.toLowerCase(),
    );

    final supportedChainsResponse = await _swapOkxRepository.getSupportedChains();
    final supportedChains = _processOkxResponse(supportedChainsResponse);
    final supportedChain = supportedChains.firstWhereOrNull(
      (chain) => chain.chainIndex == chainOkxIndex?.values.first,
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
}
