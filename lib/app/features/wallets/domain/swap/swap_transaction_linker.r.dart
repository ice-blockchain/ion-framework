// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/swaps_repository.r.dart';
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
    await ref.watch(swapsRepositoryProvider.future),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

class SwapTransactionLinker {
  SwapTransactionLinker(
    this._swapsRepository,
    this._transactionsRepository,
  );

  final SwapsRepository _swapsRepository;
  final TransactionsRepository _transactionsRepository;

  final List<SwapTransactionIdentifier> _identifiers = [
    IonSwapTxIdentifier(),
    BscSwapTxIdentifier(),
  ];

  StreamSubscription<List<SwapTransactions>>? _swapSubscription;
  StreamSubscription<List<TransactionData>>? _incomingTxSubscription;
  StreamSubscription<List<TransactionData>>? _outgoingTxSubscription;
  bool _isRunning = false;
  List<SwapTransactions> _pendingSwaps = [];

  void startWatching() {
    if (_isRunning) return;
    _isRunning = true;
    Logger.log('SwapTransactionLinker: Starting to watch for pending swaps');

    _swapSubscription = _swapsRepository
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
      _identifiers.firstWhereOrNull(
        (i) => i.networkId.toLowerCase() == networkId.toLowerCase(),
      );

  BigInt _calculateCrossChainFee({
    required String fromNetworkId,
    required String toNetworkId,
  }) {
    final sourceIdentifier = _getIdentifier(fromNetworkId);
    final destIdentifier = _getIdentifier(toNetworkId);

    final sourceFee =
        sourceIdentifier?.getCrossChainFee(isSource: true) ?? BigInt.zero;
    final destFee =
        destIdentifier?.getCrossChainFee(isSource: false) ?? BigInt.zero;

    return sourceFee + destFee;
  }

  void _onPendingSwapsChanged(List<SwapTransactions> pendingSwaps) {
    if (!_isRunning) return;

    _pendingSwaps = pendingSwaps;
    if (pendingSwaps.isNotEmpty) {
      final swapDetails = pendingSwaps
          .map(
            (s) => 'id:${s.swapId} (${s.fromNetworkId}->${s.toNetworkId}, '
                'fromTx:${s.fromTxHash ?? "pending"}, toTx:${s.toTxHash ?? "pending"})',
          )
          .join(', ');
      Logger.log(
        'SwapTransactionLinker: Watching ${pendingSwaps.length} pending swaps: [$swapDetails]',
      );
    } else {
      Logger.log('SwapTransactionLinker: No pending swaps to watch');
    }
  }

  void _onNewIncomingTransactions(List<TransactionData> transactions) {
    if (!_isRunning || _pendingSwaps.isEmpty) return;

    Logger.log(
      'SwapTransactionLinker: Processing ${transactions.length} incoming transactions '
      'against ${_pendingSwaps.length} pending swaps',
    );

    for (final tx in transactions) {
      Logger.log(
        'SwapTransactionLinker: Checking incoming tx ${tx.txHash} '
        '(${tx.network.id}, from: ${tx.senderWalletAddress}, to: ${tx.receiverWalletAddress})',
      );
      _tryMatchToTx(tx);
    }
  }

  void _onNewOutgoingTransactions(List<TransactionData> transactions) {
    if (!_isRunning) return;

    Logger.log(
      'SwapTransactionLinker: Processing ${transactions.length} outgoing transactions',
    );

    for (final tx in transactions) {
      Logger.log(
        'SwapTransactionLinker: Checking outgoing tx ${tx.txHash} '
        '(${tx.network.id}, from: ${tx.senderWalletAddress}, to: ${tx.receiverWalletAddress})',
      );
      _tryMatchFromTx(tx);
    }
  }

  Future<void> _tryMatchToTx(TransactionData tx) async {
    final receiverAddress = tx.receiverWalletAddress;
    if (receiverAddress == null) {
      Logger.log(
        'SwapTransactionLinker: Skipping to-tx match - no receiver address',
      );
      return;
    }

    final pendingSwapsForWallet = await _swapsRepository.getSwaps(
      toWalletAddresses: [receiverAddress],
      toTxHashes: [null],
    );

    Logger.log(
      'SwapTransactionLinker: Found ${pendingSwapsForWallet.length} pending swaps '
      'for wallet $receiverAddress',
    );

    for (final swap in pendingSwapsForWallet) {
      final destIdentifier = _getIdentifier(swap.toNetworkId);
      if (destIdentifier == null) {
        Logger.log(
          'SwapTransactionLinker: No identifier for network ${swap.toNetworkId}, '
          'skipping swap ${swap.swapId}',
        );
        continue;
      }

      final crossChainFee = _calculateCrossChainFee(
        fromNetworkId: swap.fromNetworkId,
        toNetworkId: swap.toNetworkId,
      );

      if (destIdentifier.isToTxMatch(swap, tx, crossChainFee: crossChainFee)) {
        Logger.log(
          'SwapTransactionLinker: ✓ To-tx LINKED! '
          'Swap ${swap.swapId} (fromTx: ${swap.fromTxHash}) -> toTx: ${tx.txHash}',
        );
        await _swapsRepository.updateToTxHash(
          swapId: swap.swapId,
          toTxHash: tx.txHash,
        );
      }
    }
  }

  Future<void> _tryMatchFromTx(TransactionData tx) async {
    final swapsWithoutFromTx = await _swapsRepository.getSwaps(
      fromTxHashes: [null],
    );

    Logger.log(
      'SwapTransactionLinker: Found ${swapsWithoutFromTx.length} swaps without from-tx tx',
    );

    for (final swap in swapsWithoutFromTx) {
      final identifier = _getIdentifier(swap.fromNetworkId);
      if (identifier == null) {
        Logger.log(
          'SwapTransactionLinker: No identifier for network ${swap.fromNetworkId}, '
          'skipping swap ${swap.swapId}',
        );
        continue;
      }

      if (identifier.isFromTxMatch(swap, tx)) {
        Logger.log(
          'SwapTransactionLinker: ✓ From-tx LINKED! '
          'Swap ${swap.swapId} <- fromTx: ${tx.txHash}',
        );
        await _swapsRepository.updateFromTxHash(
          swapId: swap.swapId,
          fromTxHash: tx.txHash,
        );
      }
    }
  }
}
