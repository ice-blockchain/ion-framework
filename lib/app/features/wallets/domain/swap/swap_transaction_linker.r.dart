// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/swap_transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/swap/identifiers/bsc_swap_tx_identifier.dart';
import 'package:ion/app/features/wallets/domain/swap/identifiers/ion_swap_tx_identifier.dart';
import 'package:ion/app/features/wallets/domain/swap/identifiers/swap_transaction_identifier.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_transaction_linker.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapTransactionLinker> swapTransactionLinker(Ref ref) async {
  return SwapTransactionLinker(
    ref.watch(swapTransactionsDaoProvider),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

class SwapTransactionLinker {
  SwapTransactionLinker(
    this._swapTransactionsDao,
    this._transactionsRepository,
  );

  final SwapTransactionsDao _swapTransactionsDao;
  final TransactionsRepository _transactionsRepository;

  final List<SwapTransactionIdentifier> _identifiers = [
    IonSwapTxIdentifier(),
    BscSwapTxIdentifier(),
  ];

  StreamSubscription<List<SwapTransaction>>? _swapSubscription;
  StreamSubscription<List<TransactionData>>? _incomingTxSubscription;
  StreamSubscription<List<TransactionData>>? _outgoingTxSubscription;
  bool _isRunning = false;
  List<SwapTransaction> _pendingSwaps = [];

  void startWatching() {
    if (_isRunning) return;
    _isRunning = true;
    Logger.log('SwapTransactionLinker: Starting to watch for pending swaps');

    _swapSubscription = _swapTransactionsDao
        .watchSwaps(toTxHashes: [null])
        .distinct(listEquals)
        .listen(_onPendingSwapsChanged);

    _incomingTxSubscription = _transactionsRepository
        .watchTransactions(type: TransactionType.receive)
        .distinct(
          (list1, list2) =>
              const ListEquality<TransactionData>().equals(list1, list2),
        )
        .listen(_onNewIncomingTransactions);

    _outgoingTxSubscription = _transactionsRepository
        .watchTransactions(type: TransactionType.send)
        .distinct(
          (list1, list2) =>
              const ListEquality<TransactionData>().equals(list1, list2),
        )
        .listen(_onNewOutgoingTransactions);
  }

  void stopWatching() {
    if (!_isRunning) return;
    _isRunning = false;
    Logger.log('SwapTransactionLinker: Stopping watch');
    _swapSubscription?.cancel();
    _swapSubscription = null;
    _incomingTxSubscription?.cancel();
    _incomingTxSubscription = null;
    _outgoingTxSubscription?.cancel();
    _outgoingTxSubscription = null;
    _pendingSwaps = [];
  }

  SwapTransactionIdentifier? _getIdentifier(String networkId) =>
      _identifiers.firstWhereOrNull((i) => i.networkId == networkId);

  void _onPendingSwapsChanged(List<SwapTransaction> pendingSwaps) {
    if (!_isRunning) return;

    _pendingSwaps = pendingSwaps;
    if (pendingSwaps.isNotEmpty) {
      final swapIds = pendingSwaps.map((s) => s.swapId).join(', ');
      Logger.log(
        'SwapTransactionLinker: Watching ${pendingSwaps.length} pending swaps: [$swapIds]',
      );
    }
  }

  void _onNewIncomingTransactions(List<TransactionData> transactions) {
    if (!_isRunning || _pendingSwaps.isEmpty) return;

    for (final tx in transactions) {
      _tryMatchSecondLeg(tx);
    }
  }

  void _onNewOutgoingTransactions(List<TransactionData> transactions) {
    if (!_isRunning) return;

    for (final tx in transactions) {
      _tryMatchFirstLeg(tx);
    }
  }

  Future<void> _tryMatchSecondLeg(TransactionData tx) async {
    final receiverAddress = tx.receiverWalletAddress;
    if (receiverAddress == null) return;

    final pendingSwapsForWallet = await _swapTransactionsDao.getSwaps(
      toWalletAddresses: [receiverAddress],
      toTxHashes: [null],
    );

    for (final swap in pendingSwapsForWallet) {
      final identifier = _getIdentifier(swap.toNetworkId);
      if (identifier == null) continue;

      if (identifier.isSecondLegMatch(swap, tx)) {
        Logger.log(
          'SwapTransactionLinker: Found second leg match! '
          'Swap ${swap.swapId} (${swap.fromTxHash}) -> ${tx.txHash}',
        );
        await _swapTransactionsDao.updateToTxHash(
          swapId: swap.swapId,
          toTxHash: tx.txHash,
        );
      }
    }
  }

  Future<void> _tryMatchFirstLeg(TransactionData tx) async {
    final swapsWithoutFromTx = await _swapTransactionsDao.getSwaps(
      fromTxHashes: [null],
    );

    for (final swap in swapsWithoutFromTx) {
      final identifier = _getIdentifier(swap.fromNetworkId);
      if (identifier == null) continue;

      if (identifier.isFirstLegMatch(swap, tx)) {
        Logger.log(
          'SwapTransactionLinker: Found first leg match! '
          'Swap ${swap.swapId} <- ${tx.txHash}',
        );
        await _swapTransactionsDao.updateFromTxHash(
          swapId: swap.swapId,
          fromTxHash: tx.txHash,
        );
      }
    }
  }
}
