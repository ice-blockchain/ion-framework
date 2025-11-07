// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/wallets/data/models/okx_api_response.m.dart';
import 'package:ion/app/features/wallets/data/models/swap_chain_data.m.dart';
import 'package:ion/app/features/wallets/data/models/swap_quote_data.m.dart';
import 'package:ion/app/features/wallets/data/repository/swap_okx_repository.r.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_coin_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_coins_controller_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SwapCoinsController extends _$SwapCoinsController {
  @override
  SwapCoinData build() => const SwapCoinData();

  void initSellCoin({
    required CoinsGroup? coin,
    required NetworkData? network,
  }) =>
      state = state.copyWith(
        sellCoin: coin,
        sellNetwork: network,
        buyCoin: null,
        buyNetwork: null,
      );

  void setSellCoin(CoinsGroup coin) => state = state.copyWith(
        sellCoin: coin,
      );

  void setSellNetwork(NetworkData network) => state = state.copyWith(
        sellNetwork: network,
      );

  void setBuyCoin(CoinsGroup coin) => state = state.copyWith(
        buyCoin: coin,
      );

  void setBuyNetwork(NetworkData network) => state = state.copyWith(
        buyNetwork: network,
      );

  void switchCoins() {
    final sellCoin = state.sellCoin;
    final buyCoin = state.buyCoin;
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;

    state = state.copyWith(
      sellCoin: buyCoin,
      buyCoin: sellCoin,
      sellNetwork: buyNetwork,
      buyNetwork: sellNetwork,
    );
  }

  Future<({CoinsGroup? coin, NetworkData? network})> selectCoin({
    required CoinSwapType type,
    required CoinsGroup coin,
    required Future<NetworkData?> Function() selectNetworkRouteLocationBuilder,
  }) async {
    switch (type) {
      case CoinSwapType.sell:
        setSellCoin(coin);
      case CoinSwapType.buy:
        setBuyCoin(coin);
    }

    final result = await selectNetworkRouteLocationBuilder();
    if (result != null) {
      switch (type) {
        case CoinSwapType.sell:
          setSellNetwork(result);
        case CoinSwapType.buy:
          setBuyNetwork(result);
      }
    }

    return (
      coin: state.sellCoin,
      network: state.sellNetwork,
    );
  }

  // TODO(ice-erebus): implement bridge and CEX
  Future<void> swapCoins() async {
    final sellNetwork = state.sellNetwork;
    final buyNetwork = state.buyNetwork;
    final sellCoinGroup = state.sellCoin;
    final buyCoinGroup = state.buyCoin;

    if (sellCoinGroup == null || buyCoinGroup == null || sellNetwork == null || buyNetwork == null) {
      return;
    }

    final sellCoin = sellCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == sellNetwork.id);
    final buyCoin = buyCoinGroup.coins.firstWhereOrNull((coin) => coin.coin.network.id == buyNetwork.id);

    if (sellCoin == null || buyCoin == null) {
      return;
    }

    if (sellNetwork.id == buyNetwork.id) {
      final okxChain = await _isOkxChainSupported(sellNetwork);
      final sellTokenAddress = _getTokenAddress(sellCoin.coin.contractAddress);
      final buyTokenAddress = _getTokenAddress(buyCoin.coin.contractAddress);

      if (okxChain != null) {
        final swapOkxRepository = await ref.read(swapOkxRepositoryProvider.future);

        // TODO(ice-erebus): implement actual amount
        const amount = '1000';

        final quotesResponse = await swapOkxRepository.getQuotes(
          chainIndex: okxChain.chainIndex,
          amount: amount,
          fromTokenAddress: sellTokenAddress,
          toTokenAddress: buyTokenAddress,
        );

        final quotes = _processOkxResponse(quotesResponse);

        if (quotes.isNotEmpty) {
          final quote = _pickBestOkxQuote(quotes);

          final approveTransactionResponse = await swapOkxRepository.approveTransaction(
            chainIndex: quote.chainIndex,
            tokenContractAddress: sellTokenAddress,
            amount: amount,
          );

          final approveTransaction = _processOkxResponse(
            approveTransactionResponse,
          );

          return;
        }
      }
    }

    return;
  }

  Future<SwapChainData?> _isOkxChainSupported(NetworkData network) async {
    final swapOkxRepository = await ref.read(swapOkxRepositoryProvider.future);
    final supportedChainsIds = await swapOkxRepository.getSupportedChainsIds();
    final chainOkxIndex = supportedChainsIds.firstWhereOrNull(
      (chain) => chain.keys.first.toLowerCase() == network.displayName.toLowerCase(),
    );

    final supportedChainsResponse = await swapOkxRepository.getSupportedChains();
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
