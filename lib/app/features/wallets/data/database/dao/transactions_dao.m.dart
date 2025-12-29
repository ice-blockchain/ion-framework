// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/tables/coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_dao.m.g.dart';

@Riverpod(keepAlive: true)
TransactionsDao transactionsDao(Ref ref) => TransactionsDao(
      db: ref.watch(walletsDatabaseProvider),
      visibilityStatusDao: ref.watch(transactionsVisibilityStatusDaoProvider),
    );

@DriftAccessor(
  tables: [TransactionsTable, NetworksTable, CoinsTable],
)
class TransactionsDao extends DatabaseAccessor<WalletsDatabase> with _$TransactionsDaoMixin {
  TransactionsDao({
    required WalletsDatabase db,
    required this.visibilityStatusDao,
  }) : super(db);

  final TransactionsVisibilityStatusDao visibilityStatusDao;

  Future<DateTime?> lastCreatedAt() async {
    final maxCreatedAt = transactionsTable.createdAtInRelay.max();
    return (selectOnly(transactionsTable)..addColumns([maxCreatedAt]))
        .map((row) => row.read(maxCreatedAt))
        .getSingleOrNull();
  }

  Future<DateTime?> getFirstCreatedAt({DateTime? after}) async {
    final firstCreatedAt = transactionsTable.createdAtInRelay.min();
    final query = selectOnly(transactionsTable)..addColumns([firstCreatedAt]);
    if (after != null) {
      query.where(transactionsTable.createdAtInRelay.isBiggerThanValue(after));
    }
    return query.map((row) => row.read(firstCreatedAt)).getSingleOrNull();
  }

  /// Returns true if there were changes in the database
  Future<bool> save(List<Transaction> transactions) {
    return transaction(() async {
      String buildSwapKey(Transaction t) => '${t.txHash}_${t.walletViewId}';

      final existingByTxHash = await (select(transactionsTable)
            ..where(
              (t) =>
                  t.txHash.isIn(transactions.map((e) => e.txHash)) &
                  t.walletViewId.isIn(transactions.map((e) => e.walletViewId)) &
                  t.type.isIn(transactions.map((e) => e.type)),
            ))
          .get();

      // Check for existing transactions by externalHash to prevent duplicates
      final transactionsWithExternalHash =
          transactions.where((t) => t.externalHash != null).toList();
      final existingByExternalHash = transactionsWithExternalHash.isNotEmpty
          ? await (select(transactionsTable)
                ..where(
                  (t) =>
                      t.externalHash.isIn(
                        transactionsWithExternalHash.map((e) => e.externalHash!).nonNulls.toList(),
                      ) &
                      t.walletViewId.isIn(transactions.map((e) => e.walletViewId)) &
                      t.type.isIn(transactions.map((e) => e.type)),
                ))
              .get()
          : <Transaction>[];

      // Check if any incoming transaction's txHash matches an existing transaction's externalHash
      final incomingTxHashes = transactions.map((e) => e.txHash).toList();
      final existingByIncomingTxHashAsExternal = await (select(transactionsTable)
            ..where(
              (t) =>
                  t.externalHash.isIn(incomingTxHashes) &
                  t.walletViewId.isIn(transactions.map((e) => e.walletViewId)) &
                  t.type.isIn(transactions.map((e) => e.type)),
            ))
          .get();

      // Combine all existing transactions and remove duplicates
      final allExisting = <Transaction>[
        ...existingByTxHash,
        ...existingByExternalHash,
        ...existingByIncomingTxHashAsExternal,
      ]
          .fold<Map<String, Transaction>>(
            <String, Transaction>{},
            (map, tx) {
              final key = '${tx.txHash}_${tx.walletViewId}_${tx.type}';
              if (!map.containsKey(key)) {
                map[key] = tx;
              }
              return map;
            },
          )
          .values
          .toList();

      // Create a map to find existing transactions by their externalHash or txHash
      // This helps us normalize incoming transactions to use the correct txHash
      final existingByExternalHashMap = <String, Transaction>{};
      for (final tx in allExisting) {
        if (tx.externalHash != null) {
          existingByExternalHashMap[tx.externalHash!] = tx;
        }
        existingByExternalHashMap[tx.txHash] = tx;
      }

      // Normalize incoming transactions
      final normalizedTransactions = transactions.map((tx) {
        final matchedExisting = existingByExternalHashMap[tx.txHash];
        if (matchedExisting != null && matchedExisting.txHash != tx.txHash) {
          return tx.copyWith(
            txHash: matchedExisting.txHash,
            externalHash: Value(matchedExisting.externalHash ?? tx.externalHash),
          );
        }
        return tx;
      }).toList();

      final existingMap = {
        for (final e in allExisting) '${buildSwapKey(e)}_${e.type}': e,
      };

      // Detect on-chain swaps: same txHash + walletViewId, different types
      final txHashWalletPairs = <String, List<Transaction>>{};
      for (final t in [...allExisting, ...normalizedTransactions]) {
        final key = buildSwapKey(t);
        txHashWalletPairs[key] = [...(txHashWalletPairs[key] ?? []), t];
      }

      // Mark transactions as swaps if they have counterpart with different type
      final swapHashes = txHashWalletPairs.entries
          .where((e) => e.value.map((t) => t.type).toSet().length > 1)
          .map((e) => e.key)
          .toSet();

      // Update isSwap flag for detected on-chain swaps
      final transactionsWithSwapFlag = normalizedTransactions.map((t) {
        final key = buildSwapKey(t);

        if (swapHashes.contains(key) && !t.isSwap) {
          return t.copyWith(isSwap: true);
        }
        return t;
      }).toList();

      // Find existing transactions that need isSwap flag updated
      final existingToUpdate = allExisting
          .where((existingTx) {
            final key = buildSwapKey(existingTx);
            return swapHashes.contains(key) && !existingTx.isSwap;
          })
          .map((existingTx) => existingTx.copyWith(isSwap: true))
          .toList();

      final newTransactions = transactionsWithSwapFlag.where(
        (t) => !existingMap.containsKey('${buildSwapKey(t)}_${t.type}'),
      );
      final toInsert = transactionsWithSwapFlag.map((toInsertRaw) {
        final existing = existingMap['${buildSwapKey(toInsertRaw)}_${toInsertRaw.type}'];

        if (existing == null) return toInsertRaw;

        return toInsertRaw.copyWith(
          id: Value(existing.id ?? toInsertRaw.id),
          coinId: Value(existing.coinId ?? toInsertRaw.coinId),
          fee: Value(existing.fee ?? toInsertRaw.fee),
          eventId: Value(existing.eventId ?? toInsertRaw.eventId),
          userPubkey: Value(existing.userPubkey ?? toInsertRaw.userPubkey),
          dateRequested: Value(existing.dateRequested ?? toInsertRaw.dateRequested),
          dateConfirmed: Value(existing.dateConfirmed ?? toInsertRaw.dateConfirmed),
          createdAtInRelay: Value(existing.createdAtInRelay ?? toInsertRaw.createdAtInRelay),
          transferredAmount: Value(existing.transferredAmount ?? toInsertRaw.transferredAmount),
          transferredAmountUsd: Value(
            existing.transferredAmountUsd ?? toInsertRaw.transferredAmountUsd,
          ),
          assetContractAddress: Value(
            existing.assetContractAddress ?? toInsertRaw.assetContractAddress,
          ),
        );
      });
      final updatedTransactions = toInsert.where((t) {
        final existing = existingMap['${buildSwapKey(t)}_${t.type}'];
        return existing != null && existing != t;
      }).toList();

      await batch((batch) {
        batch.insertAllOnConflictUpdate(transactionsTable, toInsert);
        // Update existing transactions that are now detected as swaps
        for (final tx in existingToUpdate) {
          batch.update(
            transactionsTable,
            const TransactionsTableCompanion(isSwap: Value(true)),
            where: (tbl) =>
                tbl.txHash.equals(tx.txHash) &
                tbl.walletViewId.equals(tx.walletViewId) &
                tbl.type.equals(tx.type),
          );
        }
      });

      await visibilityStatusDao.addOrUpdateVisibilityStatus(transactions: transactionsWithSwapFlag);

      return newTransactions.isNotEmpty ||
          updatedTransactions.isNotEmpty ||
          existingToUpdate.isNotEmpty;
    });
  }

  Stream<List<TransactionData>> watchTransactions({
    List<String> coinIds = const [],
    List<String> nftIdentifiers = const [],
    List<String> txHashes = const [],
    List<String> walletAddresses = const [],
    List<String> walletViewIds = const [],
    List<String> externalHashes = const [],
    List<String> eventIds = const [],
    List<TransactionStatus> statuses = const [],
    int limit = 20,
    int? offset,
    String? symbol,
    TransactionType? type,
    DateTime? confirmedSince,
    String? networkId,
    CryptoAssetType? assetType,
  }) {
    return _createTransactionQuery(
      where: (tbl, transactionCoinAlias, nativeCoinAlias) => _buildTransactionWhereClause(
        tbl,
        coinIds: coinIds,
        nftIdentifiers: nftIdentifiers,
        txHashes: txHashes,
        walletAddresses: walletAddresses,
        walletViewIds: walletViewIds,
        externalHashes: externalHashes,
        eventIds: eventIds,
        statuses: statuses,
        symbol: symbol,
        type: type,
        networkId: networkId,
        confirmedSince: confirmedSince,
        transactionCoinAlias: transactionCoinAlias,
        assetType: assetType,
      ),
      limit: limit,
      offset: offset,
    ).watch().map((transactions) => transactions.whereType<TransactionData>().toList());
  }

  Future<List<TransactionData>> getTransactions({
    List<String> coinIds = const [],
    List<String> nftIdentifiers = const [],
    List<String> txHashes = const [],
    List<String> walletAddresses = const [],
    List<String> walletViewIds = const [],
    List<String> externalHashes = const [],
    List<String> eventIds = const [],
    List<TransactionStatus> statuses = const [],
    int limit = 20,
    int? offset,
    String? symbol,
    String? networkId,
    DateTime? confirmedSince,
    TransactionType? type,
    CryptoAssetType? assetType,
  }) async {
    final result = await _createTransactionQuery(
      where: (tbl, transactionCoinAlias, nativeCoinAlias) => _buildTransactionWhereClause(
        tbl,
        coinIds: coinIds,
        nftIdentifiers: nftIdentifiers,
        txHashes: txHashes,
        walletAddresses: walletAddresses,
        walletViewIds: walletViewIds,
        externalHashes: externalHashes,
        eventIds: eventIds,
        statuses: statuses,
        symbol: symbol,
        networkId: networkId,
        confirmedSince: confirmedSince,
        type: type,
        transactionCoinAlias: transactionCoinAlias,
        assetType: assetType,
      ),
      limit: limit,
      offset: offset,
    ).get();

    return result.whereType<TransactionData>().toList();
  }

  /// Creates the standard query with joins for transaction tables
  Selectable<TransactionData?> _createTransactionQuery({
    required Expression<bool> Function(
      $TransactionsTableTable tbl,
      $CoinsTableTable transactionCoinAlias,
      $CoinsTableTable nativeCoinAlias,
    ) where,
    int limit = 20,
    int? offset,
  }) {
    final transactionCoinAlias = alias(coinsTable, 'transactionCoin');
    final nativeCoinAlias = alias(coinsTable, 'nativeCoin');

    final query = (select(transactionsTable)
          ..where((tbl) => where(tbl, transactionCoinAlias, nativeCoinAlias))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: CustomExpression(
                    'COALESCE(${tbl.dateRequested.name}, ${tbl.createdAtInRelay.name}, ${tbl.dateConfirmed.name})',
                  ),
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit, offset: offset))
        .join([
      leftOuterJoin(
        networksTable,
        networksTable.id.equalsExp(transactionsTable.networkId),
      ),
      leftOuterJoin(
        transactionCoinAlias,
        transactionCoinAlias.id.equalsExp(transactionsTable.coinId),
      ),
      leftOuterJoin(
        nativeCoinAlias,
        nativeCoinAlias.id.equalsExp(transactionsTable.nativeCoinId),
      ),
    ]);

    return query.map(
      (row) {
        return _mapRowToDomainModel(
          row,
          nativeCoinAlias: nativeCoinAlias,
          transactionCoinAlias: transactionCoinAlias,
        );
      },
    );
  }

  /// Builds a where clause for transaction queries with common filters.
  Expression<bool> _buildTransactionWhereClause(
    $TransactionsTableTable tbl, {
    List<String> coinIds = const [],
    List<String> nftIdentifiers = const [],
    List<String> txHashes = const [],
    List<String> walletAddresses = const [],
    List<String> walletViewIds = const [],
    List<String> externalHashes = const [],
    List<String> eventIds = const [],
    List<TransactionStatus> statuses = const [],
    String? symbol,
    TransactionType? type,
    String? networkId,
    $CoinsTableTable? transactionCoinAlias,
    DateTime? confirmedSince,
    CryptoAssetType? assetType,
  }) {
    Expression<bool> expr = const Constant(true);

    if (coinIds.isNotEmpty) {
      expr = expr & tbl.coinId.isIn(coinIds);
    }

    if (nftIdentifiers.isNotEmpty) {
      expr = expr & tbl.nftIdentifier.isIn(nftIdentifiers);
    }

    if (assetType != null) {
      switch (assetType) {
        case CryptoAssetType.coin:
          expr = expr & tbl.coinId.isNotNull();
        case CryptoAssetType.nft:
          expr = expr & tbl.nftIdentifier.isNotNull();
      }
    }

    if (txHashes.isNotEmpty) {
      expr = expr & tbl.txHash.isIn(txHashes);
    }

    if (externalHashes.isNotEmpty) {
      expr = expr & tbl.externalHash.isIn(externalHashes);
    }

    if (eventIds.isNotEmpty) {
      expr = expr & tbl.eventId.isIn(eventIds);
    }

    if (walletViewIds.isNotEmpty) {
      expr = expr & tbl.walletViewId.isIn(walletViewIds);
    }

    if (symbol != null && transactionCoinAlias != null) {
      expr = expr & transactionCoinAlias.symbol.lower().equals(symbol.toLowerCase());
    }

    if (walletAddresses.isNotEmpty) {
      expr = expr &
          (tbl.receiverWalletAddress.isIn(walletAddresses) |
              tbl.senderWalletAddress.isIn(walletAddresses));
    }

    if (networkId != null) {
      expr = expr & tbl.networkId.equals(networkId);
    }

    if (statuses.isNotEmpty) {
      final statusStrings = statuses.map((s) => s.toJson()).toList();
      var statusExpr = tbl.status.isIn(statusStrings);

      // Include null status if broadcasted is in the list (null is treated as broadcasted)
      if (statuses.any((s) => s.isInProgress)) {
        statusExpr = statusExpr | tbl.status.isNull();
      }
      expr = expr & statusExpr;
    }

    if (confirmedSince != null) {
      expr = expr & tbl.dateConfirmed.isBiggerThanValue(confirmedSince);
    }

    if (type != null) {
      expr = expr & tbl.type.equals(type.value);
    }

    return expr;
  }

  Stream<TransactionData?> watchTransactionByEventId(String eventId) async* {
    final transactionCoinAlias = alias(coinsTable, 'transactionCoin');
    final nativeCoinAlias = alias(coinsTable, 'nativeCoin');

    final query = (select(transactionsTable)..where((tbl) => tbl.eventId.equals(eventId))).join([
      leftOuterJoin(
        networksTable,
        networksTable.id.equalsExp(transactionsTable.networkId),
      ),
      leftOuterJoin(
        transactionCoinAlias,
        transactionCoinAlias.id.equalsExp(transactionsTable.coinId),
      ),
      leftOuterJoin(
        nativeCoinAlias,
        nativeCoinAlias.id.equalsExp(transactionsTable.nativeCoinId),
      ),
    ]);

    yield* query
        .map(
          (row) => _mapRowToDomainModel(
            row,
            transactionCoinAlias: transactionCoinAlias,
            nativeCoinAlias: nativeCoinAlias,
          ),
        )
        .watchSingleOrNull();
  }

  /// Watches transactions that have undefined tokens (no coinId but have assetContractAddress)
  Stream<List<TransactionData>> watchUndefinedCoinTransactions() {
    final transactionCoinAlias = alias(coinsTable, 'transactionCoin');
    final nativeCoinAlias = alias(coinsTable, 'nativeCoin');

    final query = (select(transactionsTable)
          ..where(
            (tbl) =>
                tbl.coinId.isNull() &
                tbl.nftIdentifier.isNull() &
                tbl.assetContractAddress.isNotNull(),
          ))
        .join([
      leftOuterJoin(
        networksTable,
        networksTable.id.equalsExp(transactionsTable.networkId),
      ),
      leftOuterJoin(
        transactionCoinAlias,
        transactionCoinAlias.id.equalsExp(transactionsTable.coinId),
      ),
      leftOuterJoin(
        nativeCoinAlias,
        nativeCoinAlias.id.equalsExp(transactionsTable.nativeCoinId),
      ),
    ]);

    return query
        .map(
          (row) => _mapRowToDomainModel(
            row,
            transactionCoinAlias: transactionCoinAlias,
            nativeCoinAlias: nativeCoinAlias,
          ),
        )
        .watch()
        .map((transactions) => transactions.whereType<TransactionData>().toList());
  }

  TransactionData? _mapRowToDomainModel(
    TypedResult row, {
    required $CoinsTableTable nativeCoinAlias,
    required $CoinsTableTable transactionCoinAlias,
  }) {
    final transaction = row.readTable(transactionsTable);
    final network = row.readTableOrNull(networksTable);
    final nativeCoin = row.readTableOrNull(nativeCoinAlias);
    final transactionCoin = row.readTableOrNull(transactionCoinAlias);

    if (network == null) {
      throw StateError(
        'Transaction ${transaction.txHash} has no associated network',
      );
    }

    final domainNetwork = NetworkData.fromDB(network);
    final isNftTransaction = transaction.nftIdentifier != null && transaction.coinId == null;

    TransactionCryptoAsset cryptoAsset;

    if (isNftTransaction) {
      final identifierSource = transaction.nftIdentifier!;
      cryptoAsset = TransactionCryptoAsset.nftIdentifier(
        nftIdentifier: NftIdentifier.parseIdentifier(identifierSource),
        network: domainNetwork,
      );
    } else if (transactionCoin == null) {
      if (transaction.assetContractAddress != null) {
        cryptoAsset = TransactionCryptoAsset.undefinedCoin(
          contractAddress: transaction.assetContractAddress!,
          rawAmount: transaction.transferredAmount ?? '0',
        );
      } else {
        Logger.warning(
          '[TRANSACTIONS_DAO] Transaction ${transaction.txHash} has no associated coin. '
          'Coin ID: ${transaction.coinId} | Network: ${network.id} | WalletView: ${transaction.walletViewId}. '
          'This can happen when coins are removed from supported list over time. Skipping transaction.',
        );
        return null;
      }
    } else {
      final transferredAmount = transaction.transferredAmount ?? '0';
      final transferredCoin = CoinData.fromDB(transactionCoin, domainNetwork);

      cryptoAsset = TransactionCryptoAsset.coin(
        coin: transferredCoin,
        amount: fromBlockchainUnits(
          transferredAmount,
          transferredCoin.decimals,
        ),
        amountUSD: transaction.transferredAmountUsd ?? 0.0,
        rawAmount: transferredAmount,
      );
    }

    return TransactionData(
      txHash: transaction.txHash,
      walletViewId: transaction.walletViewId,
      network: domainNetwork,
      type: TransactionType.fromValue(transaction.type),
      senderWalletAddress: transaction.senderWalletAddress,
      receiverWalletAddress: transaction.receiverWalletAddress,
      nativeCoin: nativeCoin != null ? CoinData.fromDB(nativeCoin, domainNetwork) : null,
      cryptoAsset: cryptoAsset,
      id: transaction.id,
      fee: transaction.fee,
      externalHash: transaction.externalHash,
      createdAtInRelay: transaction.createdAtInRelay,
      dateConfirmed: transaction.dateConfirmed,
      dateRequested: transaction.dateRequested,
      status: transaction.status != null
          ? TransactionStatus.fromJson(transaction.status!)
          : TransactionStatus.broadcasted,
      userPubkey: transaction.userPubkey,
      eventId: transaction.eventId,
      memo: transaction.memo,
      isSwap: transaction.isSwap,
    );
  }

  Future<void> remove({
    Iterable<String> txHashes = const [],
    Iterable<String> walletViewIds = const [],
  }) async {
    if (txHashes.isEmpty && walletViewIds.isEmpty) {
      return;
    }

    await transaction(() async {
      final conditions = <Expression<bool>>[];
      final deleteQuery = delete(transactionsTable);

      if (txHashes.isNotEmpty) {
        conditions.add(transactionsTable.txHash.isIn(txHashes));
      }

      if (walletViewIds.isNotEmpty) {
        conditions.add(transactionsTable.walletViewId.isIn(walletViewIds));
      }

      if (conditions.isEmpty) {
        // Should never happen, but defensive
        throw StateError(
          'Attempted to delete transactions with no WHERE condition.',
        );
      }

      deleteQuery.where((_) => conditions.reduce((a, b) => a & b));
      await deleteQuery.go();
    });
  }
}
