// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
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
    // Wait until all preparations are completed
    await ref.watch(walletsInitializerNotifierProvider.future);

    final walletViewsService = await ref.watch(walletViewsServiceProvider.future);
    final walletViews = await walletViewsService.fetch();

    walletViewsService.walletViews.listen((walletViews) {
      state = AsyncData(walletViews);
    });

    await _setupBroadcastedTransfersListener(walletViews);

    ref.onDispose(() {
      _subscription?.cancel();
      _broadcastedTransfersSubscription?.cancel();
      _walletViewTransactions.clear();
    });

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
        .distinct((list1, list2) => const ListEquality<TransactionData>().equals(list1, list2))
        .listen(_onBroadcastedTransfersUpdate);
  }

  Future<void> _onBroadcastedTransfersUpdate(List<TransactionData> transactions) async {
    final currentTransactionsByWalletView = _groupTransactionsByWalletView(transactions);
    final affectedWalletViewIds = _findAffectedWalletViews(currentTransactionsByWalletView);

    if (affectedWalletViewIds.isNotEmpty) {
      await _refreshAffectedWalletViews(affectedWalletViewIds);
    }
  }

  /// Finds wallet view IDs that have transaction changes compared to cached state
  Set<String> _findAffectedWalletViews(Map<String, Set<String>> currentTransactionsByWalletView) {
    final affectedWalletViewIds = <String>{};

    final allWalletViewIds = <String>{
      ...currentTransactionsByWalletView.keys,
      ..._walletViewTransactions.keys,
    };

    for (final walletViewId in allWalletViewIds) {
      final currentTxs = currentTransactionsByWalletView[walletViewId] ?? <String>{};
      final cachedTxs = _walletViewTransactions[walletViewId] ?? <String>{};

      if (!const SetEquality<String>().equals(currentTxs, cachedTxs)) {
        affectedWalletViewIds.add(walletViewId);
        _walletViewTransactions[walletViewId] = currentTxs;

        Logger.info(
          '[WalletViewDataNotifier] Wallet view affected | '
          'ID: $walletViewId | '
          'Current TXs: ${currentTxs.length} | '
          'Cached TXs: ${cachedTxs.length}',
        );
      }
    }

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
