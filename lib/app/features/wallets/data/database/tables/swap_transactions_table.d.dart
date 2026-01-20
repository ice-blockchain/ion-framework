// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';

@DataClassName('SwapTransactions')
class SwapTransactionsTable extends Table {
  IntColumn get swapId => integer().autoIncrement()();
  TextColumn get fromTxHash => text().nullable()();
  TextColumn get toTxHash => text().nullable()();

  TextColumn get fromWalletAddress => text()();
  TextColumn get toWalletAddress => text()();
  TextColumn get fromNetworkId => text()();
  TextColumn get toNetworkId => text()();
  TextColumn get amount => text()();
  TextColumn get toAmount => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  String? get tableName => 'swap_transactions_table';
}
