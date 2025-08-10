// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/tables/coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/crypto_wallets_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/duration_type.dart';
import 'package:ion/app/features/wallets/data/database/tables/funds_requests_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/sync_coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transaction_visibility_status_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transactions_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallets_database.m.g.dart';

@riverpod
WalletsDatabase walletsDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final database = WalletsDatabase('test');

  onLogout(ref, database.close);

  return database;
}

// DO NOT create or use database directly, use proxy notifier
// [IONDatabaseNotifier] methods instead
@DriftDatabase(
  tables: [
    CoinsTable,
    SyncCoinsTable,
    NetworksTable,
    TransactionsTable,
    TransactionVisibilityStatusTable,
    CryptoWalletsTable,
    FundsRequestsTable,
  ],
)
class WalletsDatabase extends _$WalletsDatabase {
  WalletsDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 16;

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(name: 'wallets_database_$pubkey');
  }

  Future<bool> isColumnExists({required String tableName, required String columnName}) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }
}
