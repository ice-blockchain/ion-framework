// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coin_initializer.r.dart';
import 'package:ion/app/features/wallets/domain/networks/networks_initializer.r.dart';
import 'package:ion/app/features/wallets/domain/swap/swap_transaction_linker.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/periodic_transactions_sync_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/undefined_transactions_binder.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallets_initializer_provider.r.g.dart';

/// Completes, when wallets db and all related services are ready to use.
@riverpod
class WalletsInitializerNotifier extends _$WalletsInitializerNotifier {
  Completer<void>? _completer;

  @override
  Future<void> build() async {
    keepAliveWhenAuthenticated(ref);

    // Create a new completer only if it doesn't exist or was already completed
    if (_completer == null || _completer!.isCompleted) {
      _completer = Completer<void>();
    }

    // Just wait here, until user becomes authenticated and required data loaded
    final authState = await ref.watch(authProvider.future);
    final pubkey = ref.watch(currentPubkeySelectorProvider);

    if (authState.isAuthenticated && pubkey != null) {
      final coinInitializer = ref.watch(coinInitializerProvider);
      final networksInitializer = ref.watch(networksInitializerProvider);
      final syncServiceFuture = ref.watch(syncTransactionsServiceProvider.future);
      final periodicSyncServiceFuture = ref.watch(periodicTransactionsSyncServiceProvider.future);
      final undefinedTransactionsBinderFuture =
          ref.watch(undefinedTransactionsBinderProvider.future);
      final swapTransactionLinkerFuture = ref.watch(swapTransactionLinkerProvider.future);

      final (_, _, syncService, periodicSyncService, undefinedTransactionsBinder, swapTransactionLinker) = await (
        coinInitializer.initialize(),
        networksInitializer.initialize(),
        syncServiceFuture,
        periodicSyncServiceFuture,
        undefinedTransactionsBinderFuture,
        swapTransactionLinkerFuture,
      ).wait;

      unawaited(
        syncService.syncAll(),
      );

      // Start periodic syncing for broadcasted transactions
      periodicSyncService.startWatching();
      ref.onDispose(periodicSyncService.stopWatching);

      // Start watching for pending swap transactions
      swapTransactionLinker.startWatching();
      ref.onDispose(swapTransactionLinker.stopWatching);

      undefinedTransactionsBinder.initialize();

      // Only complete if not already completed
      if (!_completer!.isCompleted) {
        _completer!.complete();
      }
    } else {
      // Reset completer, if user logged out, so the services will be re-initialized after login
      _completer = Completer<void>();
    }

    return _completer!.future;
  }
}
