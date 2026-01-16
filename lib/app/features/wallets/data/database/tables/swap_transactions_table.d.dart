// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('SwapTransaction')
class SwapTransactionsTable extends Table {
  IntColumn get swapId => integer().autoIncrement()();
  TextColumn get fromTxHash => text()();
  TextColumn get toTxHash => text().nullable()();

  TextColumn get fromWalletAddress => text()();
  TextColumn get toWalletAddress => text()();
  TextColumn get fromNetworkId => text()();
  TextColumn get toNetworkId => text()();
  TextColumn get amount => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  String? get tableName => 'swap_transactions_table';
}
