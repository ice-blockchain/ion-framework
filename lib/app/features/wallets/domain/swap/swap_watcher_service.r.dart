// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/swap_transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_watcher_service.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapWatcherService> swapWatcherService(Ref ref) async {
  return SwapWatcherService(
    ref.watch(swapTransactionsDaoProvider),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

class SwapWatcherService {
  SwapWatcherService(this._swapTransactionsDao, this._transactionsRepository);

  static const _ionBridgeMultisigAddress =
      'Uf8PSnTugXPqSS9HgrEWdrU1yOoy2wH4qCaqsZhCaV2HSIEw';
  static const _matchingTimeWindow = Duration(minutes: 30);
  static const _amountTolerancePercent = 5.0;

  final SwapTransactionsDao _swapTransactionsDao;
  final TransactionsRepository _transactionsRepository;
  StreamSubscription<List<SwapTransaction>>? _swapSubscription;
  StreamSubscription<List<TransactionData>>? _txSubscription;
  bool _isRunning = false;
  List<SwapTransaction> _pendingSwaps = [];

  void startWatching() {
    if (_isRunning) return;
    _isRunning = true;
    Logger.log('SwapWatcherService: Starting to watch for pending swaps');

    _swapSubscription = _swapTransactionsDao
        .watchPendingSwaps()
        .distinct(listEquals)
        .listen(_onPendingSwapsChanged);

    _txSubscription = _transactionsRepository
        .watchTransactions(type: TransactionType.receive)
        .distinct(
          (list1, list2) =>
              const ListEquality<TransactionData>().equals(list1, list2),
        )
        .listen(_onNewTransactions);
  }

  void stopWatching() {
    if (!_isRunning) return;
    _isRunning = false;
    Logger.log('SwapWatcherService: Stopping watch');
    _swapSubscription?.cancel();
    _swapSubscription = null;
    _txSubscription?.cancel();
    _txSubscription = null;
    _pendingSwaps = [];
  }

  void _onPendingSwapsChanged(List<SwapTransaction> pendingSwaps) {
    if (!_isRunning) return;

    _pendingSwaps = pendingSwaps;
    if (pendingSwaps.isNotEmpty) {
      final swapIds = pendingSwaps.map((s) => s.swapId).join(', ');
      Logger.log(
        'SwapWatcherService: Watching ${pendingSwaps.length} pending swaps: [$swapIds]',
      );
    }
  }

  void _onNewTransactions(List<TransactionData> transactions) {
    if (!_isRunning || _pendingSwaps.isEmpty) return;

    for (final tx in transactions) {
      _tryMatchSecondLeg(tx);
    }
  }

  Future<void> _tryMatchSecondLeg(TransactionData tx) async {
    final receiverAddress = tx.receiverWalletAddress;
    if (receiverAddress == null) return;

    final pendingSwapsForWallet =
        await _swapTransactionsDao.getPendingSwapsForWallet(receiverAddress);

    for (final swap in pendingSwapsForWallet) {
      if (_isSecondLegMatch(swap, tx)) {
        Logger.log(
          'SwapWatcherService: Found second leg match! '
          'Swap ${swap.swapId} (${swap.fromTxHash}) -> ${tx.txHash}',
        );
        await _swapTransactionsDao.updateToTxHash(
          swapId: swap.swapId,
          toTxHash: tx.txHash,
        );
      }
    }
  }

  bool _isSecondLegMatch(SwapTransaction swap, TransactionData tx) {
    if (swap.fromNetworkId == 'bsc' && swap.toNetworkId == 'ion') {
      return _matchBscToIon(swap, tx);
    }

    if (swap.fromNetworkId == 'ion' && swap.toNetworkId == 'bsc') {
      // TODO: Implement when BSC minting works
      return false;
    }

    return false;
  }

  bool _matchBscToIon(SwapTransaction swap, TransactionData tx) {
    if (tx.network.id != 'ion') {
      return false;
    }

    if (tx.senderWalletAddress != _ionBridgeMultisigAddress) {
      return false;
    }

    if (!_isWithinTimeWindow(swap.createdAt, tx.dateConfirmed)) {
      return false;
    }

    if (!_isAmountSimilar(swap.amount, tx)) {
      return false;
    }

    Logger.log(
      'SwapWatcherService: BSC→ION match criteria met for swap ${swap.swapId}:\n'
      '  - Network: ${tx.network.id} (expected: ion)\n'
      '  - Sender: ${tx.senderWalletAddress} (expected: $_ionBridgeMultisigAddress)\n'
      '  - Time window: within ${_matchingTimeWindow.inMinutes} minutes\n'
      '  - Amount: similar to ${swap.amount}',
    );

    return true;
  }

  bool _isWithinTimeWindow(DateTime swapCreatedAt, DateTime? txConfirmedAt) {
    if (txConfirmedAt == null) return true;

    final difference = txConfirmedAt.difference(swapCreatedAt);
    return difference >= Duration.zero && difference <= _matchingTimeWindow;
  }

  bool _isAmountSimilar(String swapAmount, TransactionData tx) {
    final txRawAmount = switch (tx.cryptoAsset) {
      CoinTransactionAsset(:final rawAmount) => rawAmount,
      _ => null,
    };

    if (txRawAmount == null) return false;

    final swapAmountValue = double.tryParse(swapAmount);
    final txAmountValue = double.tryParse(txRawAmount);

    if (swapAmountValue == null || txAmountValue == null) return false;
    if (swapAmountValue == 0) return false;

    final percentDifference =
        ((swapAmountValue - txAmountValue).abs() / swapAmountValue) * 100;

    return percentDifference <= _amountTolerancePercent;
  }
}
