// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/wallets/data/database/tables/swap_transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
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
        createdAt: DateTime.now(),
        toTxHash: Value(toTxHash),
      ),
    );
  }

  Future<List<SwapTransaction>> getSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    int limit = 100,
  }) async {
    final query = select(swapTransactionsTable)
      ..where(
        (t) => _buildWhereClause(
          t,
          fromTxHashes: fromTxHashes,
          toTxHashes: toTxHashes,
          fromWalletAddresses: fromWalletAddresses,
          toWalletAddresses: toWalletAddresses,
        ),
      )
      ..limit(limit);
    return query.get();
  }

  Stream<List<SwapTransaction>> watchSwaps({
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
    int limit = 100,
  }) {
    final query = select(swapTransactionsTable)
      ..where(
        (t) => _buildWhereClause(
          t,
          fromTxHashes: fromTxHashes,
          toTxHashes: toTxHashes,
          fromWalletAddresses: fromWalletAddresses,
          toWalletAddresses: toWalletAddresses,
        ),
      )
      ..limit(limit);
    return query.watch();
  }

  Expression<bool> _buildWhereClause(
    $SwapTransactionsTableTable t, {
    List<String?> fromTxHashes = const [],
    List<String?> toTxHashes = const [],
    List<String> fromWalletAddresses = const [],
    List<String> toWalletAddresses = const [],
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

  Future<int> updateToTxHash({
    required int swapId,
    required String toTxHash,
  }) async {
    return (update(swapTransactionsTable)..where((t) => t.swapId.equals(swapId)))
        .write(SwapTransactionsTableCompanion(toTxHash: Value(toTxHash)));
  }

  Future<int> updateFromTxHash({
    required int swapId,
    required String fromTxHash,
  }) async {
    return (update(swapTransactionsTable)..where((t) => t.swapId.equals(swapId)))
        .write(SwapTransactionsTableCompanion(fromTxHash: Value(fromTxHash)));
  }
}
