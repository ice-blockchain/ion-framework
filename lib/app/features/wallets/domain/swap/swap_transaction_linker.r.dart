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
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
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

    _swapSubscription = _swapsRepository
        .watchSwaps(toTxHashes: [null])
        .distinct(listEquals)
        .listen(_onPendingSwapsChanged);

    _incomingTxSubscription = _transactionsRepository
        .watchTransactions(type: TransactionType.receive)
        .distinct(
          (list1, list2) => const ListEquality<TransactionData>().equals(list1, list2),
        )
        .listen(_onNewIncomingTransactions);

    _outgoingTxSubscription = _transactionsRepository
        .watchTransactions(type: TransactionType.send)
        .distinct(
          (list1, list2) => const ListEquality<TransactionData>().equals(list1, list2),
        )
        .listen(_onNewOutgoingTransactions);
  }

  void stopWatching() {
    if (!_isRunning) return;
    _isRunning = false;
    _swapSubscription?.cancel();
    _swapSubscription = null;
    _incomingTxSubscription?.cancel();
    _incomingTxSubscription = null;
    _outgoingTxSubscription?.cancel();
    _outgoingTxSubscription = null;
    _pendingSwaps = [];
  }

  SwapTransactionIdentifier? _getIdentifier(String networkId) =>
      _identifiers.firstWhereOrNull((i) => i.matchesNetwork(networkId));

  BigInt _calculateCrossChainFee({
    required String fromNetworkId,
    required String toNetworkId,
  }) {
    final sourceIdentifier = _getIdentifier(fromNetworkId);
    final destIdentifier = _getIdentifier(toNetworkId);

    final sourceFee = sourceIdentifier?.getCrossChainFee(isSource: true) ?? BigInt.zero;
    final destFee = destIdentifier?.getCrossChainFee(isSource: false) ?? BigInt.zero;

    return sourceFee + destFee;
  }

  void _onPendingSwapsChanged(List<SwapTransactions> pendingSwaps) {
    if (!_isRunning) return;
    _pendingSwaps = pendingSwaps;
  }

  void _onNewIncomingTransactions(List<TransactionData> transactions) {
    if (!_isRunning || _pendingSwaps.isEmpty) return;

    for (final tx in transactions) {
      _tryMatchToTx(tx);
    }
  }

  void _onNewOutgoingTransactions(List<TransactionData> transactions) {
    if (!_isRunning) return;

    for (final tx in transactions) {
      _tryMatchFromTx(tx);
    }
  }

  Future<void> _tryMatchToTx(TransactionData tx) async {
    final receiverAddress = tx.receiverWalletAddress;
    if (receiverAddress == null) return;

    final pendingSwapsForWallet = await _swapsRepository.getSwaps(
      toWalletAddresses: [receiverAddress],
      toTxHashes: [null],
    );

    for (final swap in pendingSwapsForWallet) {
      final destIdentifier = _getIdentifier(swap.toNetworkId);
      if (destIdentifier == null) continue;

      final crossChainFee = _calculateCrossChainFee(
        fromNetworkId: swap.fromNetworkId,
        toNetworkId: swap.toNetworkId,
      );

      if (destIdentifier.isToTxMatch(swap, tx, crossChainFee: crossChainFee)) {
        await _swapsRepository.updateSwap(
          swapId: swap.swapId,
          toTxHash: tx.txHash,
          status: SwapStatus.succeeded,
        );
      }
    }
  }

  Future<void> _tryMatchFromTx(TransactionData tx) async {
    final swapsWithoutFromTx = await _swapsRepository.getSwaps(
      fromTxHashes: [null],
    );

    for (final swap in swapsWithoutFromTx) {
      final identifier = _getIdentifier(swap.fromNetworkId);
      if (identifier == null) continue;

      if (identifier.isFromTxMatch(swap, tx)) {
        await _swapsRepository.updateSwap(
          swapId: swap.swapId,
          fromTxHash: tx.txHash,
        );
      }
    }
  }
}
