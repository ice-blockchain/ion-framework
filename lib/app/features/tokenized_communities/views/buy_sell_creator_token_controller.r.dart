// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/buy_creator_token_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/providers.r.dart';
import 'package:ion/app/features/tokenized_communities/views/buy_sell_creator_token_state.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buy_sell_creator_token_controller.r.g.dart';

@riverpod
class BuySellCreatorTokenController extends _$BuySellCreatorTokenController {
  Timer? _debounceTimer;

  @override
  BuySellCreatorTokenState build(String creatorPubkey) {
    ref
      ..listen(currentWalletViewDataProvider, (_, __) => _updateDerivedState())
      ..listen(walletsNotifierProvider, (_, __) => _updateDerivedState())
      ..onDispose(() => _debounceTimer?.cancel());

    _initialize();
    return const BuySellCreatorTokenState();
  }

  Future<void> _initialize() async {
    final supportedTokens = await ref.watch(supportedSwapTokensProvider.future);

    if (state.selectedPaymentToken == null && supportedTokens.isNotEmpty) {
      final defaultToken =
          supportedTokens.firstWhereOrNull((t) => t.abbreviation == 'ICE') ?? supportedTokens.first;
      selectPaymentToken(defaultToken);
    }
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
    _debouncedQuote();
  }

  void selectPaymentToken(CoinData token) {
    state = state.copyWith(selectedPaymentToken: token);
    _updateDerivedState();
    _debouncedQuote();
  }

  Future<void> _updateDerivedState() async {
    final paymentToken = state.selectedPaymentToken;
    if (paymentToken == null) {
      state = state.copyWith(
        paymentCoinsGroup: null,
        targetWallet: null,
        targetNetwork: null,
      );
      return;
    }

    final walletView = ref.read(currentWalletViewDataProvider).valueOrNull;
    final wallets = ref.read(walletsNotifierProvider).valueOrNull ?? [];

    final paymentCoinsGroup = _derivePaymentCoinsGroup(paymentToken, walletView);
    final targetWallet = _findTargetWallet(paymentToken, paymentCoinsGroup, wallets);
    final targetNetwork = await _loadTargetNetwork(targetWallet);

    state = state.copyWith(
      paymentCoinsGroup: paymentCoinsGroup,
      targetWallet: targetWallet,
      targetNetwork: targetNetwork,
    );
  }

  CoinsGroup _derivePaymentCoinsGroup(CoinData paymentToken, WalletViewData? walletView) {
    final group = walletView?.coinGroups.firstWhereOrNull(
      (g) => g.symbolGroup == paymentToken.symbolGroup,
    );
    return group ?? CoinsGroup.fromCoin(paymentToken);
  }

  Wallet? _findTargetWallet(
    CoinData paymentToken,
    CoinsGroup coinsGroup,
    List<Wallet> wallets,
  ) {
    final walletWithToken = _findWalletWithToken(
      paymentToken,
      coinsGroup,
      wallets,
    );
    if (walletWithToken != null) return walletWithToken;

    return wallets.firstWhereOrNull((w) => w.network == paymentToken.network.id);
  }

  Wallet? _findWalletWithToken(
    CoinData paymentToken,
    CoinsGroup coinsGroup,
    List<Wallet> wallets,
  ) {
    final coinInWallet = coinsGroup.coins.firstWhereOrNull(
      (c) =>
          c.coin.network.id == paymentToken.network.id &&
          c.coin.contractAddress.toLowerCase() == paymentToken.contractAddress.toLowerCase(),
    );

    if (coinInWallet?.walletId == null) return null;

    return wallets.firstWhereOrNull((w) => w.id == coinInWallet!.walletId);
  }

  Future<NetworkData?> _loadTargetNetwork(Wallet? targetWallet) async {
    if (targetWallet == null) return null;
    return ref.read(networkByIdProvider(targetWallet.network).future);
  }

  void _debouncedQuote() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _getQuote);
  }

  Future<void> _getQuote() async {
    final amount = state.amount;
    final token = state.selectedPaymentToken;

    if (amount <= 0 || token == null) {
      state = state.copyWith(isQuoting: false, quoteAmount: null);
      return;
    }

    state = state.copyWith(isQuoting: true);

    try {
      final amountIn = toBlockchainUnits(amount, token.decimals);
      final quote =
          await ref.read(buyCreatorTokenNotifierProvider(creatorPubkey).notifier).getBuyQuote(
                amountIn: amountIn,
                baseTokenAddress: token.contractAddress,
              );

      state = state.copyWith(quoteAmount: quote, isQuoting: false);
    } catch (e) {
      debugPrint('Quote error: $e');
      state = state.copyWith(quoteAmount: null, isQuoting: false);
    }
  }
}
