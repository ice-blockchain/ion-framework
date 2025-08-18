// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/tables/coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transaction_visibility_status_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transactions_visibility_status_dao.m.g.dart';

enum TransactionVisibilityStatus {
  unseen,
  seen,
}

@Riverpod(keepAlive: true)
TransactionsVisibilityStatusDao transactionsVisibilityStatusDao(Ref ref) =>
    TransactionsVisibilityStatusDao(db: ref.watch(walletsDatabaseProvider));

@DriftAccessor(
  tables: [
    TransactionsTable,
    CoinsTable,
    TransactionVisibilityStatusTable,
  ],
)
class TransactionsVisibilityStatusDao extends DatabaseAccessor<WalletsDatabase>
    with _$TransactionsVisibilityStatusDaoMixin {
  TransactionsVisibilityStatusDao({required WalletsDatabase db}) : super(db);

  Future<void> addOrUpdateVisibilityStatus({
    List<String> coinIds = const [],
    List<Transaction> transactions = const [],
    TransactionVisibilityStatus status = TransactionVisibilityStatus.unseen,
  }) async {
    if (coinIds.isNotEmpty) {
      await _addOrUpdateVisibilityStatusForCoinIds(coinIds, status);
    }

    if (transactions.isNotEmpty) {
      await _addOrUpdateVisibilityStatusForTxWalletPairs(transactions, status);
    }
  }

  Future<void> _addOrUpdateVisibilityStatusForCoinIds(
    List<String> coinIds,
    TransactionVisibilityStatus status,
  ) async {
    final transactionsForCoinIds =
        await (select(transactionsTable)..where((tbl) => tbl.coinId.isIn(coinIds))).get();

    if (transactionsForCoinIds.isEmpty) return;

    await _addOrUpdateVisibilityStatusForTxWalletPairs(transactionsForCoinIds, status);
  }

  Future<void> _addOrUpdateVisibilityStatusForTxWalletPairs(
    List<Transaction> transactions,
    TransactionVisibilityStatus status,
  ) async {
    final txWalletPairs = {for (final t in transactions) '${t.txHash}_${t.walletViewId}': t};

    final existingStatuses = await (select(transactionVisibilityStatusTable)
          ..where(
            (tbl) =>
                tbl.txHash.isIn(txWalletPairs.values.map((t) => t.txHash)) &
                tbl.walletViewId.isIn(txWalletPairs.values.map((t) => t.walletViewId)),
          ))
        .get();

    final existingMap = <String, int>{};
    for (final row in existingStatuses) {
      final key = '${row.txHash}_${row.walletViewId}';
      existingMap[key] = row.status.index;
    }

    final inserts = <TransactionVisibilityStatusTableCompanion>[];
    final updates = <TransactionVisibilityStatusTableCompanion>[];

    for (final entry in txWalletPairs.entries) {
      final key = entry.key;
      final tx = entry.value;
      final existingStatusIndex = existingMap[key];

      if (existingStatusIndex == null) {
        inserts.add(
          TransactionVisibilityStatusTableCompanion.insert(
            status: status,
            txHash: tx.txHash,
            walletViewId: tx.walletViewId,
          ),
        );
      } else if (existingStatusIndex < status.index) {
        updates.add(
          TransactionVisibilityStatusTableCompanion(
            status: Value(status),
            txHash: Value(tx.txHash),
            walletViewId: Value(tx.walletViewId),
          ),
        );
      }
    }

    await batch((batch) {
      if (inserts.isNotEmpty) {
        batch.insertAll(transactionVisibilityStatusTable, inserts);
      }
      if (updates.isNotEmpty) {
        for (final update in updates) {
          batch.update(
            transactionVisibilityStatusTable,
            update,
            where: (tbl) =>
                tbl.txHash.equals(update.txHash.value) &
                tbl.walletViewId.equals(update.walletViewId.value),
          );
        }
      }
    });
  }

  /// Gets the count of unseen transactions, optionally filtered by symbol groups
  ///
  /// If [symbolGroups] is null or empty, counts all unseen transactions.
  /// If [symbolGroups] is provided, only counts transactions for those symbol groups.
  Stream<int> getUnseenTransactionsCount({Set<String>? symbolGroups}) {
    // Early return for empty symbol groups
    if (symbolGroups != null) {
      if (symbolGroups.isEmpty) return Stream.value(0);

      final validSymbolGroups = symbolGroups.where((group) => group.isNotEmpty).toSet();
      if (validSymbolGroups.isEmpty) return Stream.value(0);

      symbolGroups = validSymbolGroups;
    }

    return _buildUnseenTransactionsQuery(symbolGroups: symbolGroups).watch().map(
      (rows) {
        final unseenCoins = <String>{};

        for (final row in rows) {
          final visibility = row.readTableOrNull(transactionVisibilityStatusTable);

          if (visibility == null || visibility.status == TransactionVisibilityStatus.unseen) {
            final transaction = row.readTable(transactionsTable);

            if (transaction.coinId == null) continue;

            final coin = row.readTable(coinsTable);
            final symbolGroup = coin.symbolGroup;

            if (symbolGroup.isNotEmpty) {
              unseenCoins.add(symbolGroup);
            }
          }
        }

        return unseenCoins.length;
      },
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildUnseenTransactionsQuery({
    List<String>? coinIds,
    Set<String>? symbolGroups,
  }) {
    var query = select(transactionsTable).join([
      leftOuterJoin(
        transactionVisibilityStatusTable,
        transactionVisibilityStatusTable.txHash.equalsExp(transactionsTable.txHash) &
            transactionVisibilityStatusTable.walletViewId.equalsExp(transactionsTable.walletViewId),
      ),
      innerJoin(
        coinsTable,
        coinsTable.id.equalsExp(transactionsTable.coinId),
      ),
    ]);

    // Only receive transactions can be unseen
    query = query..where(transactionsTable.type.equals(TransactionType.receive.value));

    if (coinIds != null && coinIds.isNotEmpty) {
      query = query..where(transactionsTable.coinId.isIn(coinIds));
    }

    if (symbolGroups != null && symbolGroups.isNotEmpty) {
      query = query..where(coinsTable.symbolGroup.isIn(symbolGroups));
    }

    return query..where(transactionsTable.coinId.isNotNull());
  }

  Stream<bool> hasUnseenTransactions(List<String> coinIds) {
    if (coinIds.isEmpty) return Stream.value(false);

    final validCoinIds = coinIds.where((id) => id.isNotEmpty).toList();
    if (validCoinIds.isEmpty) return Stream.value(false);

    return _buildUnseenTransactionsQuery(coinIds: validCoinIds).watch().map((rows) {
      for (final row in rows) {
        final visibility = row.readTableOrNull(transactionVisibilityStatusTable);

        // Check if transaction is unseen (null status means unseen)
        if (visibility == null || visibility.status == TransactionVisibilityStatus.unseen) {
          final transaction = row.readTable(transactionsTable);

          // Validate transaction has a coinId
          if (transaction.coinId != null && transaction.coinId!.isNotEmpty) return true;
        }
      }
      return false;
    });
  }
}
