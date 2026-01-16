// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/ion_swap_request.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_data.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/services/bridge_service.dart';
import 'package:ion_swap_client/services/cex_service.dart';
import 'package:ion_swap_client/services/dex_service.dart';
import 'package:ion_swap_client/services/ion_bsc_to_ion_bridge_service.dart';
import 'package:ion_swap_client/services/ion_swap_service.dart';
import 'package:ion_swap_client/services/ion_to_bsc_bridge_service.dart';

typedef SendCoinCallback = Future<void> Function({
  required String depositAddress,
  required num amount,
});

class SwapService {
  SwapService({
    required DexService okxService,
    required CexService cexService,
    required BridgeService bridgeService,
    required IonBscToIonBridgeService ionBscToIonBridgeService,
    required IonSwapService ionSwapService,
    required IonToBscBridgeService ionToBscBridgeService,
  })  : _okxService = okxService,
        _cexService = cexService,
        _bridgeService = bridgeService,
        _ionBscToIonBridgeService = ionBscToIonBridgeService,
        _ionSwapService = ionSwapService,
        _ionToBscBridgeService = ionToBscBridgeService;

  final DexService _okxService;
  final CexService _cexService;
  final BridgeService _bridgeService;
  final IonBscToIonBridgeService _ionBscToIonBridgeService;
  final IonSwapService _ionSwapService;
  final IonToBscBridgeService _ionToBscBridgeService;

  /// TODO: Remove mock. Returns hash of the out-transaction.
  Future<String> swapCoins({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
    SwapQuoteInfo? swapQuoteInfo,
    IonSwapRequest? ionSwapRequest,
  }) async {
    try {
      if (_ionToBscBridgeService.isSupportedPair(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for ION → BSC bridge');
        }

        // TODO: Remove mock
        // await _ionToBscBridgeService.bridgeToBsc(
        //   swapCoinData: swapCoinData,
        //   request: ionSwapRequest,
        // );
        await Future<void>.delayed(const Duration(seconds: 2));
        return '4b1ba4985225b599a29ca7be24ed34a0b1a84d3b7a1d3a5ecf4da1f70973eb0f';
      }

      if (_ionBscToIonBridgeService.isSupportedPair(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for on-chain bridge');
        }

        // TODO: Remove mock
        // await _ionBscToIonBridgeService.bridgeToIon(
        //   swapCoinData: swapCoinData,
        //   request: ionSwapRequest,
        // );
        await Future<void>.delayed(const Duration(seconds: 2));
        return '0xebe55cec9314e0429e4261d9695f8e1b810ccef7d53464524aad42ec0e38e632';
      }

      if (isIonBscSwap(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for on-chain swap');
        }

        // await _ionSwapService.swapCoins(
        //   swapCoinData: swapCoinData,
        //   request: ionSwapRequest,
        // );
        // TODO: Remove mock
        return '';
      }

      if (swapQuoteInfo == null) {
        throw const IonSwapException('Swap quote is required');
      }

      if (swapCoinData.isBridge) {
        // await _bridgeService.tryToBridge(
        //   swapCoinData: swapCoinData,
        //   sendCoinCallback: sendCoinCallback,
        //   swapQuoteInfo: swapQuoteInfo,
        // );
        // TODO: Remove mock
        return '';
      }

      if (swapCoinData.sellCoin.network.id == swapCoinData.buyCoin.network.id) {
        final txData = await _okxService.tryToSwapDex(
          swapCoinData: swapCoinData,
          swapQuoteInfo: swapQuoteInfo,
        );

        final isSuccessSwap = txData != null;
        // TODO: Remove mock
        if (isSuccessSwap) return '';
      }

      await _cexService.tryToCexSwap(
        swapCoinData: swapCoinData,
        sendCoinCallback: sendCoinCallback,
        swapQuoteInfo: swapQuoteInfo,
      );
      // TODO: Remove mock
      return '';
    } on Exception catch (e) {
      throw IonSwapException(
        'Failed to swap coins: $e',
      );
    }
  }

  Future<SwapQuoteInfo> getSwapQuote({
    required SwapCoinParameters swapCoinData,
    BigInt? bscBalance,
  }) async {
    try {
      if (_ionToBscBridgeService.isSupportedPair(swapCoinData)) {
        return _ionToBscBridgeService.getQuote(
          swapCoinData: swapCoinData,
        );
      }

      if (_ionBscToIonBridgeService.isSupportedPair(swapCoinData)) {
        if (bscBalance == null) {
          throw const IonSwapException('BSC wallet is required for on-chain bridge');
        }

        return _ionBscToIonBridgeService.getQuote(
          swapCoinData: swapCoinData,
          bscBalance: bscBalance,
        );
      }

      if (isIonBscSwap(swapCoinData)) {
        if (bscBalance == null) {
          throw const IonSwapException('BSC wallet is required for on-chain swap');
        }

        return _ionSwapService.getQuote(
          swapCoinData: swapCoinData,
          bscBalance: bscBalance,
        );
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

      if (swapCoinData.sellCoin.network.id == swapCoinData.buyCoin.network.id) {
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

  bool isIonBscSwap(SwapCoinParameters swapCoinData) {
    return _ionSwapService.isSupportedPair(swapCoinData) ||
        _ionBscToIonBridgeService.isSupportedPair(swapCoinData) ||
        _ionToBscBridgeService.isSupportedPair(swapCoinData);
  }
}
