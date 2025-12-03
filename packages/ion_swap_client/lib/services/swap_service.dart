// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/services/bridge_service.dart';
import 'package:ion_swap_client/services/cex_service.dart';
import 'package:ion_swap_client/services/dex_service.dart';

typedef SendCoinCallback = Future<void> Function({
  required String depositAddress,
  required num amount,
});

class SwapService {
  SwapService({
    required DexService okxService,
    required CexService cexService,
    required BridgeService bridgeService,
  })  : _okxService = okxService,
        _cexService = cexService,
        _bridgeService = bridgeService;

  final DexService _okxService;
  final CexService _cexService;
  final BridgeService _bridgeService;

  Future<void> swapCoins({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
    required SwapQuoteInfo swapQuoteInfo,
  }) async {
    try {
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
      throw IonSwapException(
        'Failed to get swap quote: $e',
      );
    }
  }
}
