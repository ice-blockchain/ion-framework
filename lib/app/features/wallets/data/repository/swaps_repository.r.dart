// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/coins_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/networks_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/swap_transactions_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/expected_swap_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/swap_details.f.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swaps_repository.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapsRepository> swapsRepository(Ref ref) async {
  return SwapsRepository(
    ref.watch(swapTransactionsDaoProvider),
    await ref.watch(transactionsRepositoryProvider.future),
    ref.watch(coinsDaoProvider),
    ref.watch(networksDaoProvider),
  );
}

class SwapsRepository {
  SwapsRepository(
    this._swapDao,
    this._transactionsRepository,
    this._coinsDao,
    this._networksDao,
  );

  final SwapTransactionsDao _swapDao;
  final TransactionsRepository _transactionsRepository;
  final CoinsDao _coinsDao;
  final NetworksDao _networksDao;

  Future<SwapDetails?> getSwapDetails({
    required String txHash,
    required String walletViewId,
    required String walletViewName,
  }) async {
    final swap = await _findSwapByTxHash(txHash);
    if (swap == null) return null;

    final (fromTx, toTx, expectedSellData, expectedBuyData) = await (
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
      _buildExpectedSwapData(
        coinId: swap.fromCoinId,
        networkId: swap.fromNetworkId,
        amount: swap.amount,
      ),
      _buildExpectedSwapData(
        coinId: swap.toCoinId,
        networkId: swap.toNetworkId,
        amount: swap.toAmount,
      ),
    ).wait;

    return SwapDetails(
      swapId: swap.swapId,
      sellAmount: swap.amount,
      buyAmount: swap.toAmount,
      createdAt: swap.createdAt,
      status: SwapStatus.fromString(swap.status) ?? SwapStatus.pending,
      exchangeRate: swap.exchangeRate,
      fromTransaction: fromTx,
      toTransaction: toTx,
      expectedSellData: expectedSellData,
      expectedBuyData: expectedBuyData,
    );
  }

  Future<ExpectedSwapData?> _buildExpectedSwapData({
    required String coinId,
    required String networkId,
    required String amount,
  }) async {
    final coinData = await _coinsDao.getById(coinId);
    if (coinData == null) return null;

    final networkDb = await _networksDao.getById(networkId);
    if (networkDb == null) return null;

    final network = NetworkData.fromDB(networkDb);
    final coinsGroup = CoinsGroup.fromCoin(coinData);

    return ExpectedSwapData(
      coinsGroup: coinsGroup,
      network: network,
      amount: amount,
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
    required String fromCoinId,
    required String toCoinId,
    required double exchangeRate,
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
        fromCoinId: fromCoinId,
        toCoinId: toCoinId,
        exchangeRate: exchangeRate,
        fromTxHash: fromTxHash,
        toTxHash: toTxHash,
      );

  Future<int> updateSwap({
    required int swapId,
    String? fromTxHash,
    String? toTxHash,
    SwapStatus? status,
  }) =>
      _swapDao.updateSwap(
        swapId: swapId,
        fromTxHash: fromTxHash,
        toTxHash: toTxHash,
        status: status,
      );

  Future<List<SwapTransactions>> getPendingSwapsOlderThan(DateTime cutoff) =>
      _swapDao.getPendingSwapsOlderThan(cutoff);

  Future<List<SwapTransactions>> getSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
    int limit = 100,
  }) =>
      _swapDao.getSwaps(
        fromTxHashes: fromTxHashes,
        toTxHashes: toTxHashes,
        fromWalletAddresses: fromWalletAddresses,
        toWalletAddresses: toWalletAddresses,
        statuses: statuses,
        limit: limit,
      );

  Stream<List<SwapTransactions>> watchSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
    int limit = 100,
  }) =>
      _swapDao.watchSwaps(
        fromTxHashes: fromTxHashes,
        toTxHashes: toTxHashes,
        fromWalletAddresses: fromWalletAddresses,
        toWalletAddresses: toWalletAddresses,
        statuses: statuses,
        limit: limit,
      );

  Future<List<SwapTransactions>> getIncompleteSwaps({int limit = 100}) =>
      _swapDao.getIncompleteSwaps(limit: limit);
}
