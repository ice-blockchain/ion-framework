// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/exceptions/okx_exceptions.dart';
import 'package:ion_swap_client/models/chain_data.m.dart';
import 'package:ion_swap_client/models/okx_api_response.m.dart';
import 'package:ion_swap_client/models/okx_swap_transaction.m.dart';
import 'package:ion_swap_client/models/swap_chain_data.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/utils/crypto_amount_converter.dart';

class DexService {
  DexService({
    required SwapOkxRepository swapOkxRepository,
    required ChainsIdsRepository chainsIdsRepository,
  })  : _swapOkxRepository = swapOkxRepository,
        _chainsIdsRepository = chainsIdsRepository;

  final SwapOkxRepository _swapOkxRepository;
  final ChainsIdsRepository _chainsIdsRepository;

  // Returns transaction data if swap was successful, null otherwise
  Future<OkxSwapTransaction?> tryToSwapDex({
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
      final amount = toBlockchainUnits(swapCoinData.amount, int.parse(okxQuote.fromToken.decimal));

      final approveTransactionResponse = await _swapOkxRepository.approveTransaction(
        chainIndex: okxQuote.chainIndex,
        tokenContractAddress: sellTokenAddress,
        amount: amount,
      );

      _processOkxResponse(approveTransactionResponse);

      final userSellAddress = swapCoinData.userSellAddress;
      if (userSellAddress == null) {
        throw const IonSwapException('OKX: User sell address is required');
      }

      final swapResponse = await _swapOkxRepository.swap(
        amount: amount,
        chainIndex: okxQuote.chainIndex,
        toTokenAddress: buyTokenAddress,
        fromTokenAddress: sellTokenAddress,
        userWalletAddress: userSellAddress,
        slippagePercent: swapCoinData.slippage,
      );

      // Send swap transaction to the blockchain, triggering the swap smart contract
      await _swapOkxRepository.broadcastSwap(
        chainIndex: okxQuote.chainIndex,
        address: userSellAddress,
      );

      final swapDataList = _processOkxResponse(swapResponse);
      if (swapDataList.isEmpty) {
        throw const IonSwapException('OKX: No swap data returned');
      }

      return swapDataList.first.tx;
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
      final amount = toBlockchainUnits(swapCoinData.amount, swapCoinData.sellCoin.decimal);
      final quotesResponse = await _swapOkxRepository.getQuotes(
        amount: amount,
        chainIndex: okxChain.chainIndex,
        toTokenAddress: buyTokenAddress,
        fromTokenAddress: sellTokenAddress,
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
