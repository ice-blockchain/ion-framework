// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_provider.r.g.dart';

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  StreamSubscription<List<TransactionData>>? _transactionSubscription;

  @override
  TransactionDetails? build({
    required String walletViewId,
    required String txHash,
  }) {
    ref.onDispose(() {
      _transactionSubscription?.cancel();
    });

    _initializeSubscription(walletViewId, txHash);
    
    return null; // Initial state
  }

  Future<void> _initializeSubscription(String walletViewId, String txHash) async {
    final repository = await ref.read(transactionsRepositoryProvider.future);
    
    _transactionSubscription = repository.watchTransactions(
      txHashes: [txHash],
      walletViewIds: [walletViewId],
      limit: 1,
    ).listen((transactions) {
      if (transactions.isEmpty) {
        state = null;
        return;
      }

      final transaction = transactions.first;

      // For coin transactions, we need to create a basic CoinsGroup
      CoinsGroup? coinsGroup;
      if (transaction.cryptoAsset.mapOrNull(coin: (coin) => coin) != null) {
        // Create a minimal coins group from the transaction data
        final coinAsset = transaction.cryptoAsset.mapOrNull(coin: (coin) => coin)!;
        final coin = coinAsset.coin;
        coinsGroup = CoinsGroup(
          name: coin.name,
          iconUrl: coin.iconUrl,
          symbolGroup: coin.symbolGroup,
          abbreviation: coin.abbreviation,
          coins: [],
        );
      }

      state = TransactionDetails.fromTransactionData(
        transaction,
        coinsGroup: coinsGroup ??
            const CoinsGroup(
              name: '',
              iconUrl: '',
              symbolGroup: '',
              abbreviation: '',
              coins: [],
            ),
        walletViewName: null,
      );
    });
  }
}
