// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/tables/coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/swap_transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
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
  tables: [TransactionsTable, NetworksTable, CoinsTable, SwapTransactionsTable],
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

      // Query transactions matching by txHash, walletViewId, type
      // We'll match by index in application code (empty string for pending transactions)
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
      // Key includes index to handle multiple legs of same transaction
      final allExisting = <Transaction>[
        ...existingByTxHash,
        ...existingByExternalHash,
        ...existingByIncomingTxHashAsExternal,
      ]
          .fold<Map<String, Transaction>>(
            <String, Transaction>{},
            (map, tx) {
              final key = '${tx.txHash}_${tx.walletViewId}_${tx.type}_${tx.index}';
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

      // Create map with full key including index
      final existingMap = {
        for (final e in allExisting) '${buildSwapKey(e)}_${e.type}_${e.index}': e,
      };

      // Create maps for incompleted transactions (index=empty string)
      // Basic key: txHash_walletViewId_type (for basic matching - all incomplete transactions)
      // Extended key: txHash_walletViewId_type_sender_receiver (for extended matching - only those with eventId/userPubkey)
      String buildBasicIncompletedTransactionKey(Transaction t) => '${buildSwapKey(t)}_${t.type}';
      String buildExtendedIncompletedTransactionKey(Transaction t) =>
          '${buildBasicIncompletedTransactionKey(t)}_${t.senderWalletAddress ?? 'null'}_${t.receiverWalletAddress ?? 'null'}';

      // All incompleted transactions by basic key (for deletion)
      final basicIncompletedTransactionsMap = <String, List<Transaction>>{};
      // Incompleted transactions with eventId/userPubkey by extended key (for data copying)
      final extendedIncompletedTransactionsMap = <String, Transaction>{};

      for (final e in allExisting) {
        // Include transactions with empty index (pending/broadcasted) that should be replaced by confirmed transactions
        if (e.index.isEmpty) {
          // Add to basic map (for deletion)
          final basicKey = buildBasicIncompletedTransactionKey(e);
          basicIncompletedTransactionsMap.putIfAbsent(basicKey, () => []).add(e);

          // Add to extended map if it has ion pay/relay metadata (for data copying)
          if (e.eventId != null || e.userPubkey != null) {
            final extendedKey = buildExtendedIncompletedTransactionKey(e);
            if (!extendedIncompletedTransactionsMap.containsKey(extendedKey)) {
              extendedIncompletedTransactionsMap[extendedKey] = e;
            }
          }
        }
      }

      final newTransactions = normalizedTransactions.where(
        (t) => !existingMap.containsKey('${buildSwapKey(t)}_${t.type}_${t.index}'),
      );

      // Track incompleted transactions that will be deleted
      // - Basic matches: all incomplete transactions matching by basic key (will be deleted)
      // - Extended matches: incomplete transactions matching by extended key (will be deleted and data used for update)
      // Use Set to avoid duplicates (a transaction could match both extended and basic, but we only process one path)
      final incompletedTransactionsToDelete = <Transaction>{};

      final toInsert = normalizedTransactions.map((toInsertRaw) {
        // First try exact match including index
        var existing =
            existingMap['${buildSwapKey(toInsertRaw)}_${toInsertRaw.type}_${toInsertRaw.index}'];

        // If no exact match and incoming has non-empty index, check for incompleted transactions (index=empty string).
        // This handles the case where incompleted transaction becomes confirmed with actual index.
        //
        // Matching rules:
        // - Extended matching: match incompleted transactions that have eventId or userPubkey,
        //   requiring senderWalletAddress and receiverWalletAddress to match. Use their data for update.
        // - Basic matching: match all incompleted transactions by txHash, walletViewId, type.
        //   Delete them but don't use their data for update.
        if (existing == null && toInsertRaw.index.isNotEmpty) {
          // 1) Try extended matching first (for data copying)
          final extendedKey = buildExtendedIncompletedTransactionKey(toInsertRaw);
          final extendedMatch = extendedIncompletedTransactionsMap[extendedKey];

          if (extendedMatch != null) {
            existing = extendedMatch;
            // Mark this incompleted transaction for deletion since we're updating it with a new index
            incompletedTransactionsToDelete.add(extendedMatch);
          } else {
            // 2) Try basic matching (for deletion only, no data copying)
            final basicKey = buildBasicIncompletedTransactionKey(toInsertRaw);
            final basicMatches = basicIncompletedTransactionsMap[basicKey];

            if (basicMatches != null && basicMatches.isNotEmpty) {
              // Mark all basic matches for deletion (but don't use their data)
              incompletedTransactionsToDelete.addAll(basicMatches);
            }
            // Explicitly ensure existing is null - we don't use data from basic matches
            existing = null;
          }
        }

        if (existing == null) return toInsertRaw;

        final statusChanged = existing.status != toInsertRaw.status;

        final fee =
            statusChanged ? toInsertRaw.fee ?? existing.fee : existing.fee ?? toInsertRaw.fee;
        final transferredAmount = statusChanged
            ? toInsertRaw.transferredAmount ?? existing.transferredAmount
            : existing.transferredAmount ?? toInsertRaw.transferredAmount;
        final transferredAmountUsd = statusChanged
            ? toInsertRaw.transferredAmountUsd ?? existing.transferredAmountUsd
            : existing.transferredAmountUsd ?? toInsertRaw.transferredAmountUsd;

        // When updating from incompleted transaction (index was empty string, now has value),
        // copy eventId, userPubkey, and createdAtInRelay from the incompleted transaction.
        // If existing.index is empty, it means we matched an incompleted transaction via extended matching.
        final isIncompletedMatch = existing.index.isEmpty;

        return toInsertRaw.copyWith(
          id: Value(existing.id ?? toInsertRaw.id),
          coinId: Value(existing.coinId ?? toInsertRaw.coinId),
          fee: Value(fee),
          eventId: Value(
            isIncompletedMatch ? (existing.eventId ?? toInsertRaw.eventId) : toInsertRaw.eventId,
          ),
          userPubkey: Value(
            isIncompletedMatch
                ? (existing.userPubkey ?? toInsertRaw.userPubkey)
                : toInsertRaw.userPubkey,
          ),
          dateRequested: Value(existing.dateRequested ?? toInsertRaw.dateRequested),
          dateConfirmed: Value(existing.dateConfirmed ?? toInsertRaw.dateConfirmed),
          createdAtInRelay: Value(
            isIncompletedMatch
                ? (existing.createdAtInRelay ?? toInsertRaw.createdAtInRelay)
                : toInsertRaw.createdAtInRelay,
          ),
          transferredAmount: Value(transferredAmount),
          transferredAmountUsd: Value(transferredAmountUsd),
          assetContractAddress: Value(
            existing.assetContractAddress ?? toInsertRaw.assetContractAddress,
          ),
          index: toInsertRaw.index,
        );
      });
      final updatedTransactions = toInsert.where((t) {
        final existing = existingMap['${buildSwapKey(t)}_${t.type}_${t.index}'];
        return existing != null && existing != t;
      }).toList();

      await batch((batch) {
        // Delete incompleted transactions that are being updated with actual index
        // (since primary key changes, we need to delete old row first)
        // Both pending and broadcasted transactions should be replaced when confirmed transaction arrives
        // Basic matches are deleted without data copying, extended matches are deleted with data copying
        if (incompletedTransactionsToDelete.isNotEmpty) {
          for (final pendingOrBroadcastedTx in incompletedTransactionsToDelete) {
            batch.deleteWhere(
              transactionsTable,
              (t) =>
                  t.txHash.equals(pendingOrBroadcastedTx.txHash) &
                  t.walletViewId.equals(pendingOrBroadcastedTx.walletViewId) &
                  t.type.equals(pendingOrBroadcastedTx.type) &
                  t.index.equals(''),
            );
          }
        }
        batch.insertAllOnConflictUpdate(transactionsTable, toInsert);
      });

      await visibilityStatusDao.addOrUpdateVisibilityStatus(transactions: normalizedTransactions);

      return newTransactions.isNotEmpty || updatedTransactions.isNotEmpty;
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
    final swapFromTxAlias = alias(swapTransactionsTable, 'swapFromTx');
    final swapToTxAlias = alias(swapTransactionsTable, 'swapToTx');

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
      leftOuterJoin(
        swapFromTxAlias,
        swapFromTxAlias.fromTxHash.equalsExp(transactionsTable.txHash),
      ),
      leftOuterJoin(
        swapToTxAlias,
        swapToTxAlias.toTxHash.equalsExp(transactionsTable.txHash),
      ),
    ]);

    return query.map(
      (row) {
        return _mapRowToDomainModel(
          row,
          nativeCoinAlias: nativeCoinAlias,
          transactionCoinAlias: transactionCoinAlias,
          swapFromTxAlias: swapFromTxAlias,
          swapToTxAlias: swapToTxAlias,
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
    final swapFromTxAlias = alias(swapTransactionsTable, 'swapFromTx');
    final swapToTxAlias = alias(swapTransactionsTable, 'swapToTx');

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
      leftOuterJoin(
        swapFromTxAlias,
        swapFromTxAlias.fromTxHash.equalsExp(transactionsTable.txHash),
      ),
      leftOuterJoin(
        swapToTxAlias,
        swapToTxAlias.toTxHash.equalsExp(transactionsTable.txHash),
      ),
    ]);

    yield* query
        .map(
          (row) => _mapRowToDomainModel(
            row,
            transactionCoinAlias: transactionCoinAlias,
            nativeCoinAlias: nativeCoinAlias,
            swapFromTxAlias: swapFromTxAlias,
            swapToTxAlias: swapToTxAlias,
          ),
        )
        .watchSingleOrNull();
  }

  /// Watches transactions that have undefined tokens (no coinId but have assetContractAddress)
  Stream<List<TransactionData>> watchUndefinedCoinTransactions() {
    final transactionCoinAlias = alias(coinsTable, 'transactionCoin');
    final nativeCoinAlias = alias(coinsTable, 'nativeCoin');
    final swapFromTxAlias = alias(swapTransactionsTable, 'swapFromTx');
    final swapToTxAlias = alias(swapTransactionsTable, 'swapToTx');

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
      leftOuterJoin(
        swapFromTxAlias,
        swapFromTxAlias.fromTxHash.equalsExp(transactionsTable.txHash),
      ),
      leftOuterJoin(
        swapToTxAlias,
        swapToTxAlias.toTxHash.equalsExp(transactionsTable.txHash),
      ),
    ]);

    return query
        .map(
          (row) => _mapRowToDomainModel(
            row,
            transactionCoinAlias: transactionCoinAlias,
            nativeCoinAlias: nativeCoinAlias,
            swapFromTxAlias: swapFromTxAlias,
            swapToTxAlias: swapToTxAlias,
          ),
        )
        .watch()
        .map((transactions) => transactions.whereType<TransactionData>().toList());
  }

  TransactionData? _mapRowToDomainModel(
    TypedResult row, {
    required $CoinsTableTable nativeCoinAlias,
    required $CoinsTableTable transactionCoinAlias,
    $SwapTransactionsTableTable? swapFromTxAlias,
    $SwapTransactionsTableTable? swapToTxAlias,
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
      final amount = fromBlockchainUnits(transferredAmount, transferredCoin.decimals);
      final amountUSD = transaction.transferredAmountUsd ?? (amount * transferredCoin.priceUSD);

      cryptoAsset = TransactionCryptoAsset.coin(
        coin: transferredCoin,
        amount: amount,
        amountUSD: amountUSD,
        rawAmount: transferredAmount,
      );
    }

    final swapFromTx = swapFromTxAlias != null ? row.readTableOrNull(swapFromTxAlias) : null;
    final swapToTx = swapToTxAlias != null ? row.readTableOrNull(swapToTxAlias) : null;

    final swap = swapFromTx ?? swapToTx;
    final swapStatus = swap != null ? SwapStatus.fromString(swap.status) : null;

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
      swapStatus: swapStatus,
      index: transaction.index,
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
