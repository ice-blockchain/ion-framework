// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('SwapTransaction')
class SwapTransactionsTable extends Table {
  IntColumn get swapId => integer().autoIncrement()();
  TextColumn get fromTxHash => text()();
  TextColumn get toTxHash => text().nullable()();

  @override
  String? get tableName => 'swap_transactions_table';
}
