// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/chain_data.m.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';

class DexService {
  DexService({
    required SwapOkxRepository swapOkxRepository,
    required ChainsIdsRepository chainsIdsRepository,
  })  : _swapOkxRepository = swapOkxRepository,
        _chainsIdsRepository = chainsIdsRepository;

  final SwapOkxRepository _swapOkxRepository;
  final ChainsIdsRepository _chainsIdsRepository;

  // Returns true if swap was successful, false otherwise
  Future<bool> tryToSwapDex(SwapCoinParameters swapCoinData) async {
    final okxChain = await _getOkxChain(swapCoinData.sellCoinNetworkName);
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

        final userSellAddress = swapCoinData.userSellAddress;
        if (userSellAddress == null) {
          throw const IonSwapException('OKX: User sell address is required');
        }

        await _swapOkxRepository.swap(
          chainIndex: quote.chainIndex,
          amount: swapCoinData.amount,
          toTokenAddress: buyTokenAddress,
          fromTokenAddress: sellTokenAddress,
          userWalletAddress: userSellAddress,
        );

        // TODO(ice-erebus): replace to transaction
        await _swapOkxRepository.simulateSwap();

        return true;
      }
    }

    return false;
  }

  Future<SwapChainData?> _getOkxChain(String networkName) async {
    final results = await Future.wait([
      _chainsIdsRepository.getOkxChainsIds(),
      _swapOkxRepository.getSupportedChains(),
    ]);

    final supportedChainsIds = results[0] as List<ChainData>;
    final supportedChainsResponse = results[1] as OkxApiResponse<List<SwapChainData>>;

    final chainOkxData = supportedChainsIds.firstWhereOrNull(
      (chain) => chain.name.toLowerCase() == networkName.toLowerCase(),
    );
    final supportedChains = _processOkxResponse(supportedChainsResponse);
    final supportedChain = supportedChains.firstWhereOrNull(
      (chain) => chain.chainIndex == chainOkxData?.networkId,
    );

    return supportedChain;
  }

  // TODO(ice-erebus): implement actual logic (this one in PR with UI)
  SwapQuoteData _pickBestOkxQuote(List<SwapQuoteData> quotes) {
    return quotes.first;
  }

  String _getTokenAddressForOkx(String contractAddress) {
    return contractAddress.isEmpty ? _nativeTokenAddress : contractAddress;
  }

  String get _nativeTokenAddress => '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  T _processOkxResponse<T>(OkxApiResponse<T> response) {
    final responseCode = int.tryParse(response.code);
    if (responseCode == 0) {
      return response.data;
    }

    throw IonSwapException('Failed to process OKX response: $responseCode');
  }

  Future<SwapQuoteData?> getQuotes(SwapCoinParameters swapCoinData) async {
    final okxChain = await _getOkxChain(swapCoinData.sellCoinNetworkName);
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

        return quote;
      }
    }

    return null;
  }


}
