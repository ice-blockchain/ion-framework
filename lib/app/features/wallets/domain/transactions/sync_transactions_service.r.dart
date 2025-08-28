// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/crypto_wallets_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/transactions/transaction_loader.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_status_updater.r.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_transactions_service.r.g.dart';

@Riverpod(keepAlive: true)
Future<SyncTransactionsService> syncTransactionsService(Ref ref) async {
  return SyncTransactionsService(
    await ref.watch(walletsNotifierProvider.future),
    ref.watch(networksRepositoryProvider),
    await ref.watch(cryptoWalletsRepositoryProvider),
    await ref.watch(transactionLoaderProvider.future),
    await ref.watch(transferStatusUpdaterProvider.future),
    await ref.watch(walletViewsServiceProvider.future),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

/// Loads the available wallet history, and on subsequent calls, synchronizes it.
/// For tier-2 network wallets, does the same, but for transfers.
/// In case of an error, logs it and skips the wallet.
class SyncTransactionsService {
  SyncTransactionsService(
    this._userWallets,
    this._networksRepository,
    this._cryptoWalletsRepository,
    this._transactionLoader,
    this._transferStatusUpdater,
    this._walletViewsService,
    this._transactionsRepository,
  );

  final List<Wallet> _userWallets;
  final NetworksRepository _networksRepository;
  final CryptoWalletsRepository _cryptoWalletsRepository;
  final WalletViewsService _walletViewsService;
  final TransactionsRepository _transactionsRepository;

  final TransactionLoader _transactionLoader;
  final TransferStatusUpdater _transferStatusUpdater;
  final Map<String, NetworkData> _cachedNetworks = {};

  Future<void> syncAll() async {
    await _userWallets.map((wallet) async {
      final isHistoryLoaded =
          await _cryptoWalletsRepository.isHistoryLoadedForWallet(walletId: wallet.id);

      await _syncWallet(
        wallet: wallet,
        isFullLoad: !isHistoryLoaded,
        updateHistoryLoaded: true,
      );
    }).wait;
  }

  Future<void> syncBroadcastedTransfers() async {
    final walletsToSync = await _getWalletsWithBroadcastedTransfers();

    if (walletsToSync.isEmpty) {
      Logger.info('No broadcasted transfers found, skipping sync');
      return;
    }

    await _syncWallets(
      wallets: walletsToSync,
      isFullLoad: false,
      updateHistoryLoaded: false,
    );

    Logger.info('Completed syncing wallets with broadcasted transfers');
  }

  Future<List<Wallet>> _getWalletsWithBroadcastedTransfers() async {
    final broadcastedTransfers = await _transactionsRepository.getBroadcastedTransfers();

    if (broadcastedTransfers.isEmpty) return [];

    final walletsWithBroadcastedTransfers =
        broadcastedTransfers.map((tx) => tx.senderWalletAddress).whereType<String>().toSet();

    return _userWallets
        .where((wallet) => walletsWithBroadcastedTransfers.contains(wallet.address))
        .toList();
  }

  Future<void> syncBroadcastedTransactionsForWallet(String walletAddress) async {
    final wallet = _userWallets.firstWhereOrNull((w) => w.address == walletAddress);

    if (wallet == null) {
      Logger.error('Wallet with address $walletAddress not found');
      throw WalletNotFoundException(walletAddress: walletAddress);
    }

    final inProgressTransactions = await _transactionsRepository.getTransactions(
      statuses: TransactionStatus.inProgressStatuses,
      walletAddresses: [walletAddress],
    );

    if (inProgressTransactions.isEmpty) {
      Logger.info('No broadcasted transactions found for wallet $walletAddress, skipping sync');
      return;
    }

    await _syncWallets(
      wallets: [wallet],
      isFullLoad: false,
      updateHistoryLoaded: false,
    );

    Logger.info(
      'Completed syncing wallet $walletAddress with transactions (${inProgressTransactions.length} in progress)\n'
      '${inProgressTransactions.map((tx) => tx.txHash).join('\n')}',
    );
  }

  /// Syncs transactions for a specific coin across all networks/wallets
  Future<void> syncCoinTransactions(String symbolGroup) async {
    final walletsWithCoin = await _getWalletsWithCoin(symbolGroup);

    if (walletsWithCoin.isEmpty) {
      Logger.info('No wallets found with coin symbolGroup: $symbolGroup');
      return;
    }

    await _syncWallets(
      wallets: walletsWithCoin,
      isFullLoad: false,
      updateHistoryLoaded: false,
    );

    Logger.info('Completed syncing coin $symbolGroup across all networks');
  }

  Future<List<Wallet>> _getWalletsWithCoin(String symbolGroup) async {
    final walletViews = await _getWalletViews();

    return _userWallets.where((wallet) {
      final walletView = walletViews[wallet.id];
      if (walletView == null) return false;

      return walletView.coinGroups.any((group) => group.symbolGroup == symbolGroup);
    }).toList();
  }

  Future<void> _syncWallets({
    required List<Wallet> wallets,
    required bool isFullLoad,
    required bool updateHistoryLoaded,
  }) async {
    await wallets.map((wallet) async {
      await _syncWallet(
        wallet: wallet,
        isFullLoad: isFullLoad,
        updateHistoryLoaded: updateHistoryLoaded,
      );
    }).wait;
  }

  Future<void> _syncWallet({
    required Wallet wallet,
    required bool isFullLoad,
    required bool updateHistoryLoaded,
  }) async {
    final networks = await _getNetworks();
    final walletViews = await _getWalletViews();

    final network = networks[wallet.network];
    final walletViewId = walletViews[wallet.id]?.id;

    if (network == null) {
      final message = '${wallet.network} network is not supported. '
          'Skip history sync for the wallet (id: ${wallet.id}, address: ${wallet.address}).';
      Logger.error(message);
      return;
    }

    if (walletViewId == null) {
      final message =
          'Wallet (id: ${wallet.id}, address: ${wallet.address}) is not connected to any existed wallet view. '
          'Skip history sync.';
      Logger.info(message);
      return;
    }

    if (network.isIonHistorySupported) {
      await _transactionLoader.load(
        wallet: wallet,
        walletViewId: walletViewId,
        isFullLoad: isFullLoad,
      );
    }

    await _transferStatusUpdater.update(wallet);

    if (updateHistoryLoaded && isFullLoad) {
      await _cryptoWalletsRepository.save(wallet: wallet, isHistoryLoaded: true);
    }
  }

  Future<Map<String, NetworkData>> _getNetworks() async {
    if (_cachedNetworks.isEmpty) {
      _cachedNetworks.addAll(await _networksRepository.getAllAsMap());
    }
    return _cachedNetworks;
  }

  Future<Map<String, WalletViewData>> _getWalletViews() async {
    final walletViews = _walletViewsService.lastEmitted.isNotEmpty
        ? _walletViewsService.lastEmitted
        : await _walletViewsService.walletViews.first;

    return walletViews.walletIdToWalletView();
  }
}

extension on List<WalletViewData> {
  Map<String, WalletViewData> walletIdToWalletView() {
    final walletIdToWalletView = <String, WalletViewData>{};

    for (final walletView in this) {
      for (final coin in walletView.coins) {
        if (coin.walletId case final String walletId) {
          walletIdToWalletView[walletId] = walletView;
        }
      }
    }

    return walletIdToWalletView;
  }
}
