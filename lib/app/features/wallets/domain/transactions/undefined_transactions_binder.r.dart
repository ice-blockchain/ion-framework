// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_parser.dart';
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
    ref.watch(coinsRepositoryProvider),
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
    this._coinsRepository,
  );

  final WalletViewsService _walletViewsService;
  final TransactionsRepository _transactionsRepository;
  final CoinsRepository _coinsRepository;

  StreamSubscription<_WalletViewsWithUndefinedTransactions>? _subscription;

  Map<String, String>? _cachedContractMapping;
  List<WalletViewData>? _cachedWalletViews;

  void initialize() {
    final walletViewsStream = _walletViewsService.walletViews;
    final undefinedTransactionsStream = _transactionsRepository.watchUndefinedCoinTransactions();

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

    await _updateTransactionsWithCoinIds(bindableTransactions);

    Logger.info(
      'UndefinedTransactionsBinder: Successfully bound ${bindableTransactions.length} transactions',
    );
  }

  Map<String, String> _buildContractToCoinMapping(List<WalletViewData> walletViews) {
    if (_cachedContractMapping != null &&
        _cachedWalletViews != null &&
        const ListEquality<WalletViewData>().equals(_cachedWalletViews, walletViews)) {
      return _cachedContractMapping!;
    }

    final mapping = <String, String>{};

    for (final walletView in walletViews) {
      for (final coin in walletView.coins) {
        if (coin.walletAssetContractAddress case final String contractAddress) {
          final key = _buildContractKey(contractAddress, coin.coin.network.id);
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
        undefinedCoin: (contractAddress, _) => contractAddress,
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

  Future<void> _updateTransactionsWithCoinIds(List<_TransactionBinding> bindings) async {
    for (final binding in bindings) {
      double? calculatedTransferredAmountUsd;
      final transactions = await _transactionsRepository.getTransactions(
        txHashes: [binding.txHash],
        walletViewIds: [binding.walletViewId],
        limit: 1,
      );
      final rawTransferredAmount = transactions.isNotEmpty
          ? transactions.first.cryptoAsset.when(
              coin: (_, __, ___, rawAmount) => rawAmount,
              undefinedCoin: (_, rawAmount) => rawAmount,
              nft: (_) => null,
              nftIdentifier: (_, __) => null,
            )
          : null;

      if (rawTransferredAmount != null && rawTransferredAmount != '0') {
        final coin = await _coinsRepository.getCoinById(binding.coinId);
        if (coin != null) {
          final amount = parseCryptoAmount(rawTransferredAmount, coin.decimals);
          calculatedTransferredAmountUsd = amount * coin.priceUSD;
        } else {
          Logger.warning(
            'UndefinedTransactionsBinder: Coin ${binding.coinId} not found for USD calculation',
          );
        }
      }

      await _transactionsRepository.updateTransaction(
        txHash: binding.txHash,
        walletViewId: binding.walletViewId,
        coinId: binding.coinId,
        transferredAmountUsd: calculatedTransferredAmountUsd,
      );

      Logger.log(
        'UndefinedTransactionsBinder: Completed binding operation for transaction ${binding.txHash} '
        'to coin ${binding.coinId} with wallet view ${binding.walletViewId}',
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
