// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/providers/selected_wallet_view_id_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallets_initializer_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_view_data_provider.r.g.dart';

@Riverpod(keepAlive: true)
class WalletViewsDataNotifier extends _$WalletViewsDataNotifier {
  StreamSubscription<List<WalletViewData>>? _subscription;
  StreamSubscription<List<TransactionData>>? _broadcastedTransfersSubscription;
  final Map<String, Set<String>> _walletViewTransactions = {};

  @override
  Future<List<WalletViewData>> build() async {
    final startTime = DateTime.now();
    Logger.info('[WalletViewsDataNotifier] Provider build started at $startTime');

    // Wait until all preparations are completed
    await ref.watch(walletsInitializerNotifierProvider.future);
    Logger.info('[WalletViewsDataNotifier] WalletsInitializer completed');

    final walletViewsService = await ref.watch(walletViewsServiceProvider.future);
    Logger.info('[WalletViewsDataNotifier] WalletViewsService obtained');

    final walletViews = await walletViewsService.fetch();
    Logger.info('[WalletViewsDataNotifier] Fetched ${walletViews.length} wallet views');

    // Log initial balances
    for (final walletView in walletViews) {
      for (final coinGroup in walletView.coinGroups) {
        Logger.info(
            '[WalletViewsDataNotifier] Initial balance for ${coinGroup.symbolGroup}: ${coinGroup.totalAmount} (USD: \$${coinGroup.totalBalanceUSD.toStringAsFixed(2)})');
      }
    }

    walletViewsService.walletViews.listen((walletViews) {
      Logger.info(
          '[WalletViewsDataNotifier] Received wallet views update from service - ${walletViews.length} views');

      // Log updated balances
      for (final walletView in walletViews) {
        for (final coinGroup in walletView.coinGroups) {
          Logger.info(
              '[WalletViewsDataNotifier] Updated balance from service for ${coinGroup.symbolGroup}: ${coinGroup.totalAmount} (USD: \$${coinGroup.totalBalanceUSD.toStringAsFixed(2)})');
        }
      }

      state = AsyncData(walletViews);
      Logger.info('[WalletViewsDataNotifier] State updated with new wallet views');
    });

    await _setupBroadcastedTransfersListener(walletViews);

    ref.onDispose(() {
      Logger.info('[WalletViewsDataNotifier] Provider disposed');
      _subscription?.cancel();
      _broadcastedTransfersSubscription?.cancel();
      _walletViewTransactions.clear();
    });

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    Logger.info(
        '[WalletViewsDataNotifier] Provider build completed in ${duration}ms, returning ${walletViews.length} wallet views');

    return walletViews;
  }

  Future<void> _setupBroadcastedTransfersListener(List<WalletViewData> walletViews) async {
    await _broadcastedTransfersSubscription?.cancel();

    if (walletViews.isEmpty) return;

    final transactionsRepository = await ref.read(transactionsRepositoryProvider.future);
    final walletViewIds = walletViews.map((view) => view.id).toList();

    final currentTransactions = await transactionsRepository.getTransactions(
      type: TransactionType.send,
      walletViewIds: walletViewIds,
      statuses: TransactionStatus.inProgressStatuses,
    );

    _initializeTransactionCache(currentTransactions);

    _broadcastedTransfersSubscription = transactionsRepository
        .watchTransactions(
          type: TransactionType.send,
          walletViewIds: walletViewIds,
          statuses: TransactionStatus.inProgressStatuses,
        )
        .listen(_onBroadcastedTransfersUpdate);
  }

  Future<void> _onBroadcastedTransfersUpdate(List<TransactionData> transactions) async {
    final timestamp = DateTime.now();
    Logger.info(
        '[WalletViewDataNotifier] _onBroadcastedTransfersUpdate called at $timestamp with ${transactions.length} transactions');

    // Log detailed transaction information
    for (final transaction in transactions) {
      final asset = transaction.cryptoAsset;
      if (asset is CoinTransactionAsset) {
        Logger.info('[WalletViewDataNotifier] Transaction update: ${transaction.txHash}');
        Logger.info('[WalletViewDataNotifier]   - Status: ${transaction.status}');
        Logger.info('[WalletViewDataNotifier]   - Coin: ${asset.coin.abbreviation}');
        Logger.info('[WalletViewDataNotifier]   - Amount: ${asset.amount}');
        Logger.info('[WalletViewDataNotifier]   - Sender: ${transaction.senderWalletAddress}');
        Logger.info('[WalletViewDataNotifier]   - WalletViewId: ${transaction.walletViewId}');
      }
    }

    final currentTransactionsByWalletView = _groupTransactionsByWalletView(transactions);
    Logger.info(
        '[WalletViewDataNotifier] Grouped transactions by wallet view: ${currentTransactionsByWalletView.keys.length} wallet views affected');

    for (final entry in currentTransactionsByWalletView.entries) {
      final walletViewId = entry.key;
      final txHashes = entry.value;
      Logger.info(
          '[WalletViewDataNotifier] Wallet view $walletViewId has ${txHashes.length} transactions: ${txHashes.join(", ")}');
    }

    final affectedWalletViewIds = _findAffectedWalletViews(currentTransactionsByWalletView);
    Logger.info(
        '[WalletViewDataNotifier] Found ${affectedWalletViewIds.length} affected wallet view IDs: ${affectedWalletViewIds.join(", ")}');

    if (affectedWalletViewIds.isNotEmpty) {
      Logger.info(
          '[WalletViewDataNotifier] Refreshing ${affectedWalletViewIds.length} affected wallet views');
      await _refreshAffectedWalletViews(affectedWalletViewIds);
      Logger.info('[WalletViewDataNotifier] Finished refreshing affected wallet views');
    } else {
      Logger.info('[WalletViewDataNotifier] No wallet views need refreshing');
    }
  }

  /// Finds wallet view IDs that have transaction changes compared to cached state
  Set<String> _findAffectedWalletViews(Map<String, Set<String>> currentTransactionsByWalletView) {
    Logger.info('[WalletViewDataNotifier] _findAffectedWalletViews checking for changes');
    final affectedWalletViewIds = <String>{};

    final allWalletViewIds = <String>{
      ...currentTransactionsByWalletView.keys,
      ..._walletViewTransactions.keys,
    };

    Logger.info(
        '[WalletViewDataNotifier] Checking ${allWalletViewIds.length} total wallet view IDs for transaction changes');

    for (final walletViewId in allWalletViewIds) {
      final currentTxs = currentTransactionsByWalletView[walletViewId] ?? <String>{};
      final cachedTxs = _walletViewTransactions[walletViewId] ?? <String>{};

      Logger.info('[WalletViewDataNotifier] Comparing transactions for wallet view $walletViewId:');
      Logger.info(
          '[WalletViewDataNotifier]   - Current transactions (${currentTxs.length}): ${currentTxs.isEmpty ? 'none' : currentTxs.join(', ')}');
      Logger.info(
          '[WalletViewDataNotifier]   - Cached transactions (${cachedTxs.length}): ${cachedTxs.isEmpty ? 'none' : cachedTxs.join(', ')}');

      final isEqual = const SetEquality<String>().equals(currentTxs, cachedTxs);
      Logger.info('[WalletViewDataNotifier]   - Sets are equal: $isEqual');

      if (!isEqual) {
        affectedWalletViewIds.add(walletViewId);

        // Log what changed
        final addedTxs = currentTxs.difference(cachedTxs);
        final removedTxs = cachedTxs.difference(currentTxs);

        if (addedTxs.isNotEmpty) {
          Logger.info('[WalletViewDataNotifier]   - Added transactions: ${addedTxs.join(', ')}');
        }
        if (removedTxs.isNotEmpty) {
          Logger.info(
              '[WalletViewDataNotifier]   - Removed transactions: ${removedTxs.join(', ')}');
        }

        // Update cache
        final previousCache = Set<String>.from(cachedTxs);
        _walletViewTransactions[walletViewId] = currentTxs;
        Logger.info(
            '[WalletViewDataNotifier]   - Updated cache from ${previousCache.length} to ${currentTxs.length} transactions');

        Logger.info(
          '[WalletViewDataNotifier] ✓ Wallet view affected | '
          'ID: $walletViewId | '
          'Current TXs: ${currentTxs.length} | '
          'Previous Cached TXs: ${cachedTxs.length}',
        );
      } else {
        Logger.info(
            '[WalletViewDataNotifier]   - No changes detected for wallet view $walletViewId');
      }
    }

    Logger.info(
        '[WalletViewDataNotifier] Transaction comparison complete: ${affectedWalletViewIds.length} wallet views affected');
    return affectedWalletViewIds;
  }

  void _initializeTransactionCache(List<TransactionData> currentTransactions) {
    _walletViewTransactions.clear();
    final grouped = _groupTransactionsByWalletView(currentTransactions);
    _walletViewTransactions.addAll(grouped);
  }

  /// Groups transactions by wallet view id
  Map<String, Set<String>> _groupTransactionsByWalletView(List<TransactionData> transactions) {
    final grouped = <String, Set<String>>{};
    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.walletViewId, () => <String>{}).add(transaction.txHash);
    }
    return grouped;
  }

  Future<void> _refreshAffectedWalletViews(Set<String> affectedWalletViewIds) async {
    final walletViewsService = await ref.read(walletViewsServiceProvider.future);

    for (final walletViewId in affectedWalletViewIds) {
      Logger.info('[WalletViewDataNotifier] Refreshing wallet view: $walletViewId');
      await walletViewsService.refresh(walletViewId);
    }
  }

  Future<void> create(String walletViewName) async {
    final walletViewsService = await ref.read(walletViewsServiceProvider.future);
    await walletViewsService.create(walletViewName);
  }

  Future<void> delete(String walletViewId) async {
    final walletViewsService = await ref.read(walletViewsServiceProvider.future);
    await walletViewsService.delete(walletViewId: walletViewId);
  }

  Future<void> updateWalletView({
    required WalletViewData walletView,
    String? updatedName,
    List<CoinData>? updatedCoinsList,
  }) async {
    final walletViewsService = await ref.read(walletViewsServiceProvider.future);
    await walletViewsService.update(
      walletView: walletView,
      updatedName: updatedName,
      updatedCoinsList: updatedCoinsList,
    );
  }
}

@riverpod
Future<String> currentWalletViewId(Ref ref) async {
  final currentWalletViewData = await ref.watch(currentWalletViewDataProvider.future);
  return currentWalletViewData.id;
}

@Riverpod(keepAlive: true)
Future<WalletViewData> currentWalletViewData(Ref ref) async {
  final savedSelectedWalletId = ref.watch(selectedWalletViewIdNotifierProvider);
  final walletsData = await ref.watch(walletViewsDataNotifierProvider.future);

  final selectedWallet =
      walletsData.firstWhereOrNull((wallet) => wallet.id == savedSelectedWalletId);
  return selectedWallet ?? walletsData.first;
}

@riverpod
Future<WalletViewData> walletViewById(Ref ref, {required String id}) async {
  final wallets = await ref.watch(walletViewsDataNotifierProvider.future);

  return wallets.firstWhere((wallet) => wallet.id == id);
}

@riverpod
Future<WalletViewData?> walletViewByAddress(
  Ref ref,
  String address,
) async {
  final wallets = await ref.watch(walletsNotifierProvider.future);
  final wallet = wallets.firstWhereOrNull((wallet) => wallet.address == address);

  if (wallet == null) {
    return null;
  }

  final walletViews = await ref.watch(walletViewsDataNotifierProvider.future);

  return walletViews.firstWhereOrNull(
    (walletView) => walletView.coins.any((coin) => coin.walletId == wallet.id),
  );
}
