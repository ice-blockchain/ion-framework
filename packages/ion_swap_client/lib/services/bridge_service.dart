// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/services/swap_service.dart';

class BridgeService {
  BridgeService({
    required RelayApiRepository relayApiRepository,
  }) : _relayApiRepository = relayApiRepository;

  final RelayApiRepository _relayApiRepository;

  Future<void> tryToBridge({
    required SwapCoinParameters swapCoinData,
    required SendCoinCallback sendCoinCallback,
    required SwapQuoteInfo swapQuoteInfo,
  }) async {
    if (swapQuoteInfo.source == SwapQuoteInfoSource.relay) {
      final relayQuote = swapQuoteInfo.relayQuote;
      final relayDepositAmount = swapQuoteInfo.relayDepositAmount;
      if (relayQuote == null || relayDepositAmount == null) {
        throw const IonSwapException('Relay: Quote is required');
      }

      final depositStep = relayQuote.steps.firstWhereOrNull((step) => step.id == 'deposit')?.items.first;
      if (depositStep == null) {
        throw const IonSwapException('Relay: Deposit step is required');
      }

      await sendCoinCallback(
        depositAddress: depositStep.data.to,
        amount: num.parse(relayDepositAmount),
      );
    }
  }

  Future<RelayQuote> getQuote(SwapCoinParameters swapCoinData) async {
    final sellAddress = swapCoinData.userSellAddress;
    final buyAddress = swapCoinData.userBuyAddress;
    if (sellAddress == null || buyAddress == null) {
      throw const IonSwapException('Sell or buy address is required');
    }

    final chains = await _relayApiRepository.getChains();
    final sellChain = chains.firstWhere(
      (chain) => chain.name.toLowerCase() == swapCoinData.sellNetworkId.toLowerCase(),
    );
    final buyChain = chains.firstWhere((chain) => chain.name.toLowerCase() == swapCoinData.buyNetworkId.toLowerCase());

    final swapAmount = _getSwapAmount(
      swapCoinData.amount,
      buyChain.currency.decimals,
    );

    final quote = await _relayApiRepository.getQuote(
      amount: swapAmount,
      user: sellAddress,
      recipient: buyAddress,
      originCurrency: _getTokenAddress(swapCoinData.sellCoinContractAddress),
      destinationCurrency: _getTokenAddress(swapCoinData.buyCoinContractAddress),
      originChainId: sellChain.id,
      destinationChainId: buyChain.id,
    );

    return quote;
  }

  String _getTokenAddress(String contractAddress) {
    return contractAddress.isEmpty ? _nativeTokenAddress : contractAddress;
  }

  String get _nativeTokenAddress => '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  String _getSwapAmount(String amount, int decimals) {
    return (BigInt.from(double.parse(amount)) * BigInt.from(10).pow(decimals)).toString();
  }
}
