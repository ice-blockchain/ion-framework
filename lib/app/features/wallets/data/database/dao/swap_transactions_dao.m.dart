// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/tables/swap_transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/swap_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_transactions_dao.m.g.dart';

@Riverpod(keepAlive: true)
SwapTransactionsDao swapTransactionsDao(Ref ref) => SwapTransactionsDao(
      db: ref.watch(walletsDatabaseProvider),
    );

@DriftAccessor(tables: [SwapTransactionsTable])
class SwapTransactionsDao extends DatabaseAccessor<WalletsDatabase>
    with _$SwapTransactionsDaoMixin {
  SwapTransactionsDao({required WalletsDatabase db}) : super(db);

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
  }) async {
    return into(swapTransactionsTable).insert(
      SwapTransactionsTableCompanion.insert(
        fromTxHash: Value(fromTxHash),
        fromWalletAddress: fromWalletAddress,
        toWalletAddress: toWalletAddress,
        fromNetworkId: fromNetworkId,
        toNetworkId: toNetworkId,
        amount: amount,
        toAmount: toAmount,
        createdAt: DateTime.now().toUtc(),
        toTxHash: Value(toTxHash),
        fromCoinId: fromCoinId,
        toCoinId: toCoinId,
        exchangeRate: exchangeRate,
      ),
    );
  }

  Future<List<SwapTransactions>> getSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
    int limit = 100,
  }) async {
    return _buildSwapsQuery(
      fromTxHashes: fromTxHashes,
      toTxHashes: toTxHashes,
      fromWalletAddresses: fromWalletAddresses,
      toWalletAddresses: toWalletAddresses,
      statuses: statuses,
      limit: limit,
    ).get();
  }

  Stream<List<SwapTransactions>> watchSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
    int limit = 100,
  }) {
    return _buildSwapsQuery(
      fromTxHashes: fromTxHashes,
      toTxHashes: toTxHashes,
      fromWalletAddresses: fromWalletAddresses,
      toWalletAddresses: toWalletAddresses,
      statuses: statuses,
      limit: limit,
    ).watch();
  }

  SimpleSelectStatement<$SwapTransactionsTableTable, SwapTransactions>
      _buildSwapsQuery({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
    int limit = 100,
  }) {
    return select(swapTransactionsTable)
      ..where(
        (t) => _buildWhereClause(
          t,
          fromTxHashes: fromTxHashes,
          toTxHashes: toTxHashes,
          fromWalletAddresses: fromWalletAddresses,
          toWalletAddresses: toWalletAddresses,
          statuses: statuses,
        ),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
  }

  Expression<bool> _buildWhereClause(
    $SwapTransactionsTableTable t, {
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    List<SwapStatus> statuses = const [],
  }) {
    Expression<bool> expr = const Constant(true);

    if (fromTxHashes.isNotEmpty) {
      expr = expr & _buildNullableColumnFilter(t.fromTxHash, fromTxHashes);
    }

    if (toTxHashes.isNotEmpty) {
      expr = expr & _buildNullableColumnFilter(t.toTxHash, toTxHashes);
    }

    if (fromWalletAddresses.isNotEmpty) {
      expr = expr & t.fromWalletAddress.isIn(fromWalletAddresses);
    }

    if (toWalletAddresses.isNotEmpty) {
      expr = expr & t.toWalletAddress.isIn(toWalletAddresses);
    }

    if (statuses.isNotEmpty) {
      expr = expr & t.status.isIn(statuses.map((s) => s.name).toList());
    }

    return expr;
  }

  Expression<bool> _buildNullableColumnFilter(
    GeneratedColumn<String> column,
    List<String?> values,
  ) {
    final hasNull = values.contains(null);
    final nonNullValues = values.whereType<String>().toList();

    if (hasNull && nonNullValues.isEmpty) {
      return column.isNull();
    } else if (!hasNull && nonNullValues.isNotEmpty) {
      return column.isIn(nonNullValues);
    } else {
      return column.isNull() | column.isIn(nonNullValues);
    }
  }

  Future<int> updateSwap({
    required int swapId,
    String? fromTxHash,
    String? toTxHash,
    SwapStatus? status,
  }) async {
    final currentSwap = await (select(swapTransactionsTable)..where((t) => t.swapId.equals(swapId)))
        .getSingleOrNull();

    if (currentSwap == null) return 0;

    final companion = SwapTransactionsTableCompanion(
      fromTxHash: fromTxHash != null && currentSwap.fromTxHash == null
          ? Value(fromTxHash)
          : const Value.absent(),
      toTxHash:
          toTxHash != null && currentSwap.toTxHash == null ? Value(toTxHash) : const Value.absent(),
      status: status != null ? Value(status.name) : const Value.absent(),
    );

    return (update(swapTransactionsTable)..where((t) => t.swapId.equals(swapId))).write(companion);
  }

  Future<List<SwapTransactions>> getPendingSwapsOlderThan(DateTime cutoff) async {
    final query = select(swapTransactionsTable)
      ..where(
        (t) => t.status.equals(SwapStatus.pending.name) & t.createdAt.isSmallerThanValue(cutoff),
      );
    return query.get();
  }

  Future<List<SwapTransactions>> getIncompleteSwaps({int limit = 100}) async {
    final query = select(swapTransactionsTable)
      ..where((t) => t.fromTxHash.isNull() | t.toTxHash.isNull())
      ..limit(limit);
    return query.get();
  }
}
