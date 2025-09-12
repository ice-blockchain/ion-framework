// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'undefined_transactions_binder.r.g.dart';

typedef _WalletViewsWithUndefinedTransactions = ({
  List<WalletViewData> walletViews,
  List<TransactionData> undefinedTransactions,
});

@Riverpod(keepAlive: true)
Future<UndefinedTransactionsBinder> undefinedTransactionsBinder(Ref ref) async {
  final binder = UndefinedTransactionsBinder(
    await ref.watch(walletViewsServiceProvider.future),
    await ref.watch(transactionsRepositoryProvider.future),
  );

  ref.onDispose(binder.dispose);

  return binder;
}

/// Service that automatically binds undefined token transactions with coins
/// from wallet views when contract addresses match.
class UndefinedTransactionsBinder {
  UndefinedTransactionsBinder(
    this._walletViewsService,
    this._transactionsRepository,
  );

  final WalletViewsService _walletViewsService;
  final TransactionsRepository _transactionsRepository;

  StreamSubscription<_WalletViewsWithUndefinedTransactions>? _subscription;

  Map<String, String>? _cachedContractMapping;
  List<WalletViewData>? _cachedWalletViews;

  void initialize() {
    final walletViewsStream = _walletViewsService.walletViews;
    final undefinedTransactionsStream = _transactionsRepository.watchUndefinedTokenTransactions();

    _subscription = walletViewsStream
        .distinct((list1, list2) => const ListEquality<WalletViewData>().equals(list1, list2))
        .combineLatest(
          undefinedTransactionsStream.distinct(
            (list1, list2) => const ListEquality<TransactionData>().equals(list1, list2),
          ),
          (List<WalletViewData> walletViews, List<TransactionData> undefinedTransactions) => (
            walletViews: walletViews,
            undefinedTransactions: undefinedTransactions,
          ),
        )
        .debounce(const Duration(milliseconds: 500))
        .listen(_processBinding);
  }

  Future<void> _processBinding(_WalletViewsWithUndefinedTransactions data) async {
    if (data.walletViews.isEmpty || data.undefinedTransactions.isEmpty) {
      return;
    }

    // Build contract address to coin ID mapping
    final contractToCoinMapping = _buildContractToCoinMapping(data.walletViews);

    if (contractToCoinMapping.isEmpty) {
      Logger.info('UndefinedTransactionsBinder: No coins with contract addresses found');
      return;
    }

    // Find transactions that can be bound to coins
    final bindableTransactions = _findBindableTransactions(
      data.undefinedTransactions,
      contractToCoinMapping,
    );

    if (bindableTransactions.isEmpty) {
      Logger.info('UndefinedTransactionsBinder: No bindable transactions found');
      return;
    }

    // Update transactions with coin IDs
    await _updateTransactionsWithCoinIds(bindableTransactions);

    Logger.info(
      'UndefinedTransactionsBinder: Successfully bound ${bindableTransactions.length} transactions',
    );
  }

  Map<String, String> _buildContractToCoinMapping(List<WalletViewData> walletViews) {
    // Check if we have a cached mapping for the same wallet views
    if (_cachedContractMapping != null &&
        _cachedWalletViews != null &&
        const ListEquality<WalletViewData>().equals(_cachedWalletViews, walletViews)) {
      return _cachedContractMapping!;
    }

    final mapping = <String, String>{};

    for (final walletView in walletViews) {
      for (final coin in walletView.coins) {
        if (coin.coin.contractAddress.isNotEmpty) {
          final key = _buildContractKey(coin.coin.contractAddress, coin.coin.network.id);
          mapping[key] = coin.coin.id;
        }
      }
    }

    _cachedContractMapping = mapping;
    _cachedWalletViews = walletViews;

    return mapping;
  }

  List<_TransactionBinding> _findBindableTransactions(
    List<TransactionData> undefinedTransactions,
    Map<String, String> contractToCoinMapping,
  ) {
    final bindableTransactions = <_TransactionBinding>[];

    for (final transaction in undefinedTransactions) {
      final contractAddress = transaction.cryptoAsset.maybeWhen(
        undefinedToken: (contractAddress, symbol) => contractAddress,
        orElse: () => null,
      );

      if (contractAddress != null && contractAddress.isNotEmpty) {
        final contractKey = _buildContractKey(contractAddress, transaction.network.id);
        final coinId = contractToCoinMapping[contractKey];

        if (coinId != null) {
          bindableTransactions.add(
            _TransactionBinding(
              txHash: transaction.txHash,
              walletViewId: transaction.walletViewId,
              coinId: coinId,
            ),
          );
        }
      }
    }

    return bindableTransactions;
  }

  /// Updates transactions in the database with their corresponding coin IDs
  Future<void> _updateTransactionsWithCoinIds(List<_TransactionBinding> bindings) async {
    for (final binding in bindings) {
      await _transactionsRepository.updateTransaction(
        txHash: binding.txHash,
        walletViewId: binding.walletViewId,
        coinId: binding.coinId,
      );

      Logger.log(
        'UndefinedTransactionsBinder: Successfully bound transaction ${binding.txHash} '
        'to coin ${binding.coinId}',
      );
    }
  }

  /// Creates a unique key for contract address and network combination
  String _buildContractKey(String contractAddress, String networkId) {
    return '${contractAddress.toLowerCase()}_$networkId';
  }

  void dispose() {
    _subscription?.cancel();
    _cachedContractMapping = null;
    _cachedWalletViews = null;
  }
}

class _TransactionBinding {
  const _TransactionBinding({
    required this.txHash,
    required this.walletViewId,
    required this.coinId,
  });

  final String txHash;
  final String walletViewId;
  final String coinId;
}
