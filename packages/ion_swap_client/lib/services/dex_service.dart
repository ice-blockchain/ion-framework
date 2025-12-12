// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/exceptions/okx_exceptions.dart';
import 'package:ion_swap_client/models/chain_data.m.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
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
  Future<bool> tryToSwapDex({
    required SwapCoinParameters swapCoinData,
    required SwapQuoteInfo swapQuoteInfo,
  }) async {
    if (swapQuoteInfo.source == SwapQuoteInfoSource.okx) {
      final okxQuote = swapQuoteInfo.okxQuote;
      if (okxQuote == null) {
        throw const IonSwapException('OKX: Quote is required');
      }

      final sellTokenAddress = _getTokenAddressForOkx(swapCoinData.sellCoin.contractAddress);
      final buyTokenAddress = _getTokenAddressForOkx(swapCoinData.buyCoin.contractAddress);

      final approveTransactionResponse = await _swapOkxRepository.approveTransaction(
        chainIndex: okxQuote.chainIndex,
        tokenContractAddress: sellTokenAddress,
        amount: swapCoinData.amount,
      );

      _processOkxResponse(approveTransactionResponse);

      final userSellAddress = swapCoinData.userSellAddress;
      if (userSellAddress == null) {
        throw const IonSwapException('OKX: User sell address is required');
      }

      await _swapOkxRepository.swap(
        chainIndex: okxQuote.chainIndex,
        amount: swapCoinData.amount,
        toTokenAddress: buyTokenAddress,
        fromTokenAddress: sellTokenAddress,
        userWalletAddress: userSellAddress,
      );

      await _swapOkxRepository.broadcastSwap(
        chainIndex: okxQuote.chainIndex,
        address: userSellAddress,
      );

      return true;
    }

    throw const IonSwapException('Failed to swap on Dex: Invalid quote source');
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

  SwapQuoteData _pickBestOkxQuote(List<SwapQuoteData> quotes) {
    final sortedQuotes = quotes.sortedByCompare<double>(
      (quote) => quote.priceForSellTokenInBuyToken,
      (a, b) => b.compareTo(a),
    );
    return sortedQuotes.first;
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

    if (responseCode == null) {
      throw const IonSwapException('Failed to process OKX response');
    }

    throw OkxException.fromCode(responseCode);
  }

  Future<SwapQuoteData?> getQuotes(SwapCoinParameters swapCoinData) async {
    final okxChain = await _getOkxChain(swapCoinData.sellCoin.network.name);
    final sellTokenAddress = _getTokenAddressForOkx(swapCoinData.sellCoin.contractAddress);
    final buyTokenAddress = _getTokenAddressForOkx(swapCoinData.buyCoin.contractAddress);

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
