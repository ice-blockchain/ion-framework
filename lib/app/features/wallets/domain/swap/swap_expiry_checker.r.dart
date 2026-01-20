// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  static const Duration _matchingTimeWindow = Duration(hours: 6);
  static const Duration _checkInterval = Duration(minutes: 30);

  Timer? _expiryCheckTimer;
  bool _isRunning = false;

  void startChecking() {
    if (_isRunning) return;
    _isRunning = true;

    _checkForExpiredSwaps();

    _expiryCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkForExpiredSwaps();
    });
  }

  void stopChecking() {
    if (!_isRunning) return;
    _isRunning = false;
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = null;
  }

  Future<void> _checkForExpiredSwaps() async {
    final cutoff = DateTime.now().toUtc().subtract(_matchingTimeWindow);
    final expiredSwaps = await _swapsRepository.getPendingSwapsOlderThan(cutoff);

    if (expiredSwaps.isEmpty) return;

    for (final swap in expiredSwaps) {
      await _swapsRepository.updateSwap(
        swapId: swap.swapId,
        status: SwapStatus.failed,
      );
    }
  }
}
