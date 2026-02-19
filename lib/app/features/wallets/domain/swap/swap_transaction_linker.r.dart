// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
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
  final env = ref.watch(envProvider.notifier);
  return SwapTransactionLinker(
    swapsRepository: await ref.watch(swapsRepositoryProvider.future),
    transactionsRepository: await ref.watch(transactionsRepositoryProvider.future),
    ionSwapContractAddress: env.get(EnvVariable.CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS),
  );
}

class SwapTransactionLinker {
  SwapTransactionLinker({
    required SwapsRepository swapsRepository,
    required TransactionsRepository transactionsRepository,
    required String ionSwapContractAddress,
  })  : _swapsRepository = swapsRepository,
        _transactionsRepository = transactionsRepository,
        _identifiers = [
          IonSwapTxIdentifier(),
          BscSwapTxIdentifier(ionSwapContractAddress: ionSwapContractAddress),
        ];

  final SwapsRepository _swapsRepository;
  final TransactionsRepository _transactionsRepository;
  final List<SwapTransactionIdentifier> _identifiers;

  StreamSubscription<List<SwapTransactions>>? _swapSubscription;
  StreamSubscription<List<TransactionData>>? _incomingTxSubscription;
  StreamSubscription<List<TransactionData>>? _outgoingTxSubscription;
  bool _isRunning = false;
  List<SwapTransactions> _pendingSwaps = [];
  List<TransactionData> _lastIncomingTransactions = [];

  void startWatching() {
    if (_isRunning) return;
    _isRunning = true;

    unawaited(_reconcileExistingTransactions());

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
    _lastIncomingTransactions = [];
  }

  // Matches pending swaps against transactions that were already in the DB
  // before the live stream subscriptions started (e.g. after a history sync).
  Future<void> _reconcileExistingTransactions() async {
    final pendingSwaps = await _swapsRepository.getSwaps(toTxHashes: [null]);
    if (pendingSwaps.isNotEmpty) {
      final toWalletAddresses = pendingSwaps.map((s) => s.toWalletAddress).toSet().toList();
      final existingReceiveTxs = await _transactionsRepository.getTransactions(
        type: TransactionType.receive,
        walletAddresses: toWalletAddresses,
        limit: 100,
      );
      for (final tx in existingReceiveTxs) {
        await _tryMatchToTx(tx);
      }
    }

    final swapsWithoutFromTx = await _swapsRepository.getSwaps(fromTxHashes: [null]);
    if (swapsWithoutFromTx.isNotEmpty) {
      final fromWalletAddresses =
          swapsWithoutFromTx.map((s) => s.fromWalletAddress).toSet().toList();
      final existingSendTxs = await _transactionsRepository.getTransactions(
        type: TransactionType.send,
        walletAddresses: fromWalletAddresses,
        limit: 100,
      );
      for (final tx in existingSendTxs) {
        await _tryMatchFromTx(tx);
      }
    }
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

    if (_pendingSwaps.isNotEmpty && _lastIncomingTransactions.isNotEmpty) {
      _matchIncomingTransactions(_lastIncomingTransactions);
    }
  }

  void _onNewIncomingTransactions(List<TransactionData> transactions) {
    if (!_isRunning) return;
    _lastIncomingTransactions = transactions;

    if (_pendingSwaps.isNotEmpty) {
      _matchIncomingTransactions(transactions);
    }
  }

  void _onNewOutgoingTransactions(List<TransactionData> transactions) {
    if (!_isRunning) return;

    for (final tx in transactions) {
      _tryMatchFromTx(tx);
    }
  }

  void _matchIncomingTransactions(List<TransactionData> transactions) {
    for (final tx in transactions) {
      _tryMatchToTx(tx);
    }
  }

  Future<void> _tryMatchToTx(TransactionData tx) async {
    final receiverAddress = tx.receiverWalletAddress;
    if (receiverAddress == null) return;

    final pendingSwapsForWallet = await _swapsRepository.getSwaps(
      toWalletAddresses: [receiverAddress],
      toTxHashes: [null],
    );

    if (pendingSwapsForWallet.isEmpty) return;

    final matchedSwap = _findMatchingToSwap(pendingSwapsForWallet, tx);
    if (matchedSwap != null) {
      await _swapsRepository.updateSwap(
        swapId: matchedSwap.swapId,
        toTxHash: tx.txHash,
        status: SwapStatus.succeeded,
      );
    }
  }

  SwapTransactions? _findMatchingToSwap(
    List<SwapTransactions> swaps,
    TransactionData tx,
  ) {
    for (final swap in swaps.reversed) {
      final destIdentifier = _getIdentifier(swap.toNetworkId);
      final crossChainFee = _calculateCrossChainFee(
        fromNetworkId: swap.fromNetworkId,
        toNetworkId: swap.toNetworkId,
      );

      if (destIdentifier != null &&
          destIdentifier.isToTxMatch(swap, tx, crossChainFee: crossChainFee)) {
        return swap;
      }
    }
    return null;
  }

  Future<void> _tryMatchFromTx(TransactionData tx) async {
    final swapsWithoutFromTx = await _swapsRepository.getSwaps(
      fromTxHashes: [null],
    );

    final matchedSwap = _findMatchingFromSwap(swapsWithoutFromTx, tx);
    if (matchedSwap != null) {
      await _swapsRepository.updateSwap(
        swapId: matchedSwap.swapId,
        fromTxHash: tx.txHash,
      );
    }
  }

  SwapTransactions? _findMatchingFromSwap(
    List<SwapTransactions> swaps,
    TransactionData tx,
  ) {
    for (final swap in swaps.reversed) {
      final identifier = _getIdentifier(swap.fromNetworkId);

      if (identifier != null && identifier.isFromTxMatch(swap, tx)) {
        return swap;
      }
    }
    return null;
  }
}
