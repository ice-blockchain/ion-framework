// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/domain/transactions/sync_transactions_service.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/providers/manage_coins_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_data_sync_coordinator_provider.r.g.dart';

@riverpod
WalletDataSyncCoordinator walletDataSyncCoordinator(Ref ref) {
  return WalletDataSyncCoordinator(ref);
}

final class WalletDataSyncCoordinator {
  WalletDataSyncCoordinator(this._ref);

  final Ref _ref;

  Future<void> syncWalletData() async {
    try {
      final syncService = await _ref.read(syncTransactionsServiceProvider.future);
      await syncService.syncAll();

      _ref
        ..invalidate(walletViewsDataNotifierProvider)
        ..invalidate(manageCoinsNotifierProvider);

      await _ref.read(syncedCoinsBySymbolGroupNotifierProvider.notifier).refresh();
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to sync wallet data',
      );
    }
  }
}
