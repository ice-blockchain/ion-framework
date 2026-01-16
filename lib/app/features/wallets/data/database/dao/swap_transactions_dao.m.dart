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
    required String fromTxHash,
    String? toTxHash,
  }) async {
    return into(swapTransactionsTable).insert(
      SwapTransactionsTableCompanion.insert(
        fromTxHash: fromTxHash,
        toTxHash: Value(toTxHash),
      ),
    );
  }

  Future<SwapTransaction?> getSwapByHash(String hash) async {
    final query = select(swapTransactionsTable)
      ..where(
        (t) => t.fromTxHash.equals(hash) | t.toTxHash.equals(hash),
      );
    return query.getSingleOrNull();
  }

  Future<int> updateToTxHash({
    required int swapId,
    required String toTxHash,
  }) async {
    return (update(swapTransactionsTable)..where((t) => t.swapId.equals(swapId)))
        .write(SwapTransactionsTableCompanion(toTxHash: Value(toTxHash)));
  }

  Stream<List<SwapTransaction>> watchPendingSwaps() {
    final query = select(swapTransactionsTable)..where((t) => t.toTxHash.isNull());
    return query.watch();
  }
}
