// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/services/bridge_service.dart';
import 'package:ion_swap_client/services/cex_service.dart';
import 'package:ion_swap_client/services/dex_service.dart';
import 'package:ion_swap_client/services/ion_swap_service.dart';

typedef SendCoinCallback = Future<void> Function({
  required String depositAddress,
  required num amount,
});

class SwapService {
  SwapService({
    required DexService okxService,
    required CexService cexService,
    required BridgeService bridgeService,
    required IonSwapService ionSwapService,
  })  : _okxService = okxService,
        _cexService = cexService,
        _bridgeService = bridgeService,
        _ionSwapService = ionSwapService;

  final DexService _okxService;
  final CexService _cexService;
  final BridgeService _bridgeService;
  final IonSwapService _ionSwapService;

  Future<void> swapCoins({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
    SwapQuoteInfo? swapQuoteInfo,
    IonSwapRequest? ionSwapRequest,
  }) async {
    try {
      if (_isIonBscSwap(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for on-chain swap');
        }

        await _ionSwapService.swapCoins(
          swapCoinData: swapCoinData,
          request: ionSwapRequest,
        );
        return;
      }

      if (swapQuoteInfo == null) {
        throw const IonSwapException('Swap quote is required');
      }

      if (swapCoinData.isBridge) {
        await _bridgeService.tryToBridge(
          swapCoinData: swapCoinData,
          sendCoinCallback: sendCoinCallback,
          swapQuoteInfo: swapQuoteInfo,
        );
        return;
      }

      if (swapCoinData.sellNetworkId == swapCoinData.buyNetworkId) {
        final success = await _okxService.tryToSwapDex(
          swapCoinData: swapCoinData,
          swapQuoteInfo: swapQuoteInfo,
        );

        if (success) {
          return;
        }
      }

      await _cexService.tryToCexSwap(
        swapCoinData: swapCoinData,
        sendCoinCallback: sendCoinCallback,
        swapQuoteInfo: swapQuoteInfo,
      );
    } on Exception catch (e) {
      throw IonSwapException(
        'Failed to swap coins: $e',
      );
    }
  }

  Future<SwapQuoteInfo> getSwapQuote({
    required SwapCoinParameters swapCoinData,
  }) async {
    try {
      if (_isIonBscSwap(swapCoinData)) {
        return _ionSwapService.getQuote(swapCoinData: swapCoinData);
      }

      if (swapCoinData.isBridge) {
        final quote = await _bridgeService.getQuote(swapCoinData);

        return SwapQuoteInfo(
          type: SwapQuoteInfoType.bridge,
          priceForSellTokenInBuyToken: double.parse(quote.details.rate),
          source: SwapQuoteInfoSource.relay,
          relayQuote: quote,
          relayDepositAmount: swapCoinData.amount,
        );
      }

      if (swapCoinData.sellNetworkId == swapCoinData.buyNetworkId) {
        final quote = await _okxService.getQuotes(swapCoinData);
        if (quote == null) {
          throw const IonSwapException('Failed to get swap quote: No quote found');
        }

        return SwapQuoteInfo(
          type: SwapQuoteInfoType.cexOrDex,
          priceForSellTokenInBuyToken: quote.priceForSellTokenInBuyToken,
          source: SwapQuoteInfoSource.okx,
          okxQuote: quote,
        );
      }

      final quote = await _cexService.getCexSwapQuote(
        swapCoinData,
      );

      return quote;
    } on Exception catch (e) {
      if (e is IonSwapException) {
        rethrow;
      }

      throw IonSwapException(
        'Failed to get swap quote: $e',
      );
    }
  }

  bool _isIonBscSwap(SwapCoinParameters swapCoinData) {
    return _ionSwapService.isSupportedPair(swapCoinData);
  }
}
