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

  /// Returns the transaction hash of the swap transaction if it's exists
  /// For now only [IonSwapService] and [IonBscToIonBridgeService] are supported
  Future<String?> swapCoins({
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

        await _ionToBscBridgeService.bridgeToBsc(
          swapCoinData: swapCoinData,
          request: ionSwapRequest,
        );
        return null;
      }

      if (_ionBscToIonBridgeService.isSupportedPair(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for on-chain bridge');
        }

        final txHash = await _ionBscToIonBridgeService.bridgeToIon(
          swapCoinData: swapCoinData,
          request: ionSwapRequest,
        );
        return txHash;
      }

      if (isIonBscSwap(swapCoinData)) {
        if (ionSwapRequest == null) {
          throw const IonSwapException('Ion swap request is required for on-chain swap');
        }

        final txHash = await _ionSwapService.swapCoins(
          swapCoinData: swapCoinData,
          request: ionSwapRequest,
        );
        return txHash;
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
        return null;
      }

      if (swapCoinData.sellCoin.network.id == swapCoinData.buyCoin.network.id) {
        final txData = await _okxService.tryToSwapDex(
          swapCoinData: swapCoinData,
          swapQuoteInfo: swapQuoteInfo,
        );

        final isSuccessSwap = txData != null;
        if (isSuccessSwap) return null;
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

    return null;
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
