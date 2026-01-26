// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/swaps_repository.r.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_expiry_checker.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapExpiryChecker> swapExpiryChecker(Ref ref) async {
  return SwapExpiryChecker(
    await ref.watch(swapsRepositoryProvider.future),
  );
}

class SwapExpiryChecker {
  SwapExpiryChecker(this._swapsRepository);

  final SwapsRepository _swapsRepository;

  static const Duration matchingTimeWindow = Duration(hours: 6);

  StreamSubscription<List<SwapTransactions>>? _swapSubscription;
  Timer? _expiryTimer;
  bool _isRunning = false;
  List<SwapTransactions> _pendingSwaps = [];

  void startChecking() {
    if (_isRunning) return;
    _isRunning = true;

    _swapSubscription =
        _swapsRepository.watchSwaps(statuses: [SwapStatus.pending]).listen(_onPendingSwapsChanged);
  }

  void stopChecking() {
    if (!_isRunning) return;
    _isRunning = false;
    _swapSubscription?.cancel();
    _swapSubscription = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _pendingSwaps = [];
  }

  void _onPendingSwapsChanged(List<SwapTransactions> swaps) {
    _pendingSwaps = swaps;
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _expiryTimer?.cancel();

    if (_pendingSwaps.isEmpty) return;

    final oldest = _pendingSwaps.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );

    final expiryTime = oldest.createdAt.add(matchingTimeWindow);
    final delay = expiryTime.difference(DateTime.now().toUtc());

    if (delay <= Duration.zero) {
      _checkForExpiredSwaps();
    } else {
      _expiryTimer = Timer(delay, _checkForExpiredSwaps);
    }
  }

  Future<void> _checkForExpiredSwaps() async {
    final cutoff = DateTime.now().toUtc().subtract(matchingTimeWindow);

    for (final swap in _pendingSwaps) {
      if (swap.createdAt.isBefore(cutoff)) {
        await _swapsRepository.updateSwap(
          swapId: swap.swapId,
          status: SwapStatus.failed,
        );
      }
    }
  }
}
