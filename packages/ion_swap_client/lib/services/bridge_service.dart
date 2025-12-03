// SPDX-License-Identifier: ice License 1.0


import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/models/relay_quote.m.dart';
import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';

class BridgeService {
  BridgeService({
    required RelayApiRepository relayApiRepository,
  }) : _relayApiRepository = relayApiRepository;

  final RelayApiRepository _relayApiRepository;

  // TODO(ice-erebus): implement actual logic (this one in PR with UI)
  Future<void> tryToBridge(SwapCoinParameters swapCoinData) async {
    // await _relayApiRepository.getQuote();
  }

  Future<RelayQuote> getQuote(SwapCoinParameters swapCoinData) async {
    final sellAddress = swapCoinData.userSellAddress;
    final buyAddress = swapCoinData.userBuyAddress;
    if (sellAddress == null || buyAddress == null) {
      throw const IonSwapException('Sell or buy address is required');
    }

    final chains = await _relayApiRepository.getChains();
    final sellChain =
        chains.firstWhere((chain) => chain.name.toLowerCase() == swapCoinData.sellNetworkId.toLowerCase());
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
