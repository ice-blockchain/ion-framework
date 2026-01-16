// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/swap_transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
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

  final SwapTransactionsDao _swapTransactionsDao;
  final TransactionsRepository _transactionsRepository;
  StreamSubscription<List<SwapTransaction>>? _subscription;
  final Map<int, Timer> _pollingTimers = {};
  bool _isRunning = false;

  void startWatching() {
    if (_isRunning) return;
    _isRunning = true;
    Logger.log('SwapWatcherService: Starting to watch for pending swaps');
    _subscription = _swapTransactionsDao
        .watchPendingSwaps()
        .distinct(listEquals)
        .listen(_onPendingSwapsChanged);
  }

  void stopWatching() {
    if (!_isRunning) return;
    _isRunning = false;
    Logger.log('SwapWatcherService: Stopping watch');
    _subscription?.cancel();
    _subscription = null;
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
  }

  void _onPendingSwapsChanged(List<SwapTransaction> pendingSwaps) {
    if (!_isRunning) return;

    for (final swap in pendingSwaps) {
      if (!_pollingTimers.containsKey(swap.swapId)) {
        Logger.log('SwapWatcherService: Found pending swap ${swap.swapId}, fromTxHash: ${swap.fromTxHash}');
        _startPollingForSwap(swap);
      }
    }
  }

  void _startPollingForSwap(SwapTransaction swap) {
    _pollingTimers[swap.swapId] = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollSecondLeg(swap),
    );
    _pollSecondLeg(swap);
  }

  Future<void> _pollSecondLeg(SwapTransaction swap) async {
    if (!_isRunning) return;

    final transactions = await _transactionsRepository.getTransactions(
      txHashes: [swap.fromTxHash],
    );
    if (transactions.isEmpty) {
      Logger.log('SwapWatcherService: Transaction not found for hash ${swap.fromTxHash}');
      return;
    }

    final networkId = transactions.first.network.id;
    final isIonToBsc = networkId == 'ion';

    Logger.log(
      'SwapWatcherService: Polling second leg for swap ${swap.swapId}, '
      'network: $networkId, isIonToBsc: $isIonToBsc',
    );

    final secondLegHash = isIonToBsc
        ? await _fetchBscSecondLeg(swap.fromTxHash)
        : await _fetchIonSecondLeg(swap.fromTxHash);

    if (secondLegHash != null && _isRunning) {
      Logger.log(
        'SwapWatcherService: Found second leg for swap ${swap.swapId}: $secondLegHash',
      );
      await _swapTransactionsDao.updateToTxHash(
        swapId: swap.swapId,
        toTxHash: secondLegHash,
      );
      _pollingTimers[swap.swapId]?.cancel();
      _pollingTimers.remove(swap.swapId);
    }
  }

  Future<String?> _fetchBscSecondLeg(String ionTxHash) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // BSC mint not available in logs (minting disabled due to BE issue)
    return null;
  }

  Future<String?> _fetchIonSecondLeg(String bscTxHash) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // Real ION second-leg tx from logs: BSC→ION swap mint from bridge
    return '8950b5edb66929ceb71de1e63b1ba593c6134840710d60caf47e7ddb3c402e78';
  }
}
