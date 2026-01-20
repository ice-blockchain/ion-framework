// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/swap_transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/swap_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swaps_repository.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapsRepository> swapsRepository(Ref ref) async {
  return SwapsRepository(
    ref.watch(swapTransactionsDaoProvider),
    await ref.watch(transactionsRepositoryProvider.future),
  );
}

class SwapsRepository {
  SwapsRepository(this._swapDao, this._transactionsRepository);

  final SwapTransactionsDao _swapDao;
  final TransactionsRepository _transactionsRepository;

  Future<SwapDetails?> getSwapDetails({
    required String txHash,
    required String walletViewId,
    required String walletViewName,
  }) async {
    Logger.log('SwapsRepository: Getting swap details for txHash: $txHash');

    final swap = await _findSwapByTxHash(txHash);
    if (swap == null) {
      Logger.log('SwapsRepository: No swap found for txHash: $txHash');
      return null;
    }

    Logger.log(
      'SwapsRepository: Found swap - id: ${swap.swapId}, '
      'fromTxHash: ${swap.fromTxHash}, toTxHash: ${swap.toTxHash}',
    );

    final (fromTx, toTx) = await (
      _fetchTransactionDetails(
        swap.fromTxHash,
        walletViewId,
        walletViewName,
        TransactionType.send,
      ),
      _fetchTransactionDetails(
        swap.toTxHash,
        walletViewId,
        walletViewName,
        TransactionType.receive,
      ),
    ).wait;

    Logger.log(
      'SwapsRepository: Fetched transactions - '
      'fromTx: ${fromTx != null ? "found" : "null"}, toTx: ${toTx != null ? "found" : "null"}',
    );

    return SwapDetails(
      swapId: swap.swapId,
      sellAmount: swap.amount,
      buyAmount: swap.toAmount,
      createdAt: swap.createdAt,
      fromTransaction: fromTx,
      toTransaction: toTx,
    );
  }

  Future<SwapTransactions?> _findSwapByTxHash(String txHash) async {
    final (fromSwaps, toSwaps) = await (
      _swapDao.getSwaps(fromTxHashes: [txHash]),
      _swapDao.getSwaps(toTxHashes: [txHash]),
    ).wait;

    if (fromSwaps.isNotEmpty) return fromSwaps.first;
    return toSwaps.firstOrNull;
  }

  Future<TransactionDetails?> _fetchTransactionDetails(
    String? txHash,
    String walletViewId,
    String walletViewName,
    TransactionType type,
  ) async {
    if (txHash == null) return null;

    try {
      var transactions = await _transactionsRepository.getTransactions(
        externalHashes: [txHash],
        walletViewIds: [walletViewId],
        type: type,
        limit: 1,
      );

      if (transactions.isEmpty) {
        transactions = await _transactionsRepository.getTransactions(
          txHashes: [txHash],
          walletViewIds: [walletViewId],
          type: type,
          limit: 1,
        );
      }

      if (transactions.isEmpty) return null;

      final transaction = transactions.first;
      return TransactionDetails.fromTransactionData(
        transaction,
        coinsGroup: _buildCoinsGroup(transaction),
        walletViewName: walletViewName,
      );
    } catch (e, stack) {
      Logger.log('SwapsRepository: Error fetching transaction $txHash - $e\n$stack');
      return null;
    }
  }

  CoinsGroup? _buildCoinsGroup(TransactionData transaction) {
    final coinAsset = transaction.cryptoAsset.mapOrNull(coin: (coin) => coin);
    if (coinAsset == null) return null;
    return CoinsGroup.fromCoin(coinAsset.coin);
  }

  Future<int> saveSwap({
    required String fromWalletAddress,
    required String toWalletAddress,
    required String fromNetworkId,
    required String toNetworkId,
    required String amount,
    required String toAmount,
    String? fromTxHash,
    String? toTxHash,
  }) =>
      _swapDao.saveSwap(
        fromWalletAddress: fromWalletAddress,
        toWalletAddress: toWalletAddress,
        fromNetworkId: fromNetworkId,
        toNetworkId: toNetworkId,
        amount: amount,
        toAmount: toAmount,
        fromTxHash: fromTxHash,
        toTxHash: toTxHash,
      );

  Future<int> updateFromTxHash({
    required int swapId,
    required String fromTxHash,
  }) =>
      _swapDao.updateFromTxHash(swapId: swapId, fromTxHash: fromTxHash);

  Future<int> updateToTxHash({
    required int swapId,
    required String toTxHash,
  }) =>
      _swapDao.updateToTxHash(swapId: swapId, toTxHash: toTxHash);

  Future<List<SwapTransactions>> getSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    int limit = 100,
  }) =>
      _swapDao.getSwaps(
        fromTxHashes: fromTxHashes,
        toTxHashes: toTxHashes,
        fromWalletAddresses: fromWalletAddresses,
        toWalletAddresses: toWalletAddresses,
        limit: limit,
      );

  Stream<List<SwapTransactions>> watchSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    int limit = 100,
  }) =>
      _swapDao.watchSwaps(
        fromTxHashes: fromTxHashes,
        toTxHashes: toTxHashes,
        fromWalletAddresses: fromWalletAddresses,
        toWalletAddresses: toWalletAddresses,
        limit: limit,
      );
}
