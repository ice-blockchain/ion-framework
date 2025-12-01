// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/database.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/wallets/data/database/dao/transactions_visibility_status_dao.m.dart';
import 'package:ion/app/features/wallets/data/database/tables/coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/crypto_wallets_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/duration_type.dart';
import 'package:ion/app/features/wallets/data/database/tables/funds_requests_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/networks_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/nfts_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/sync_coins_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transaction_visibility_status_table.d.dart';
import 'package:ion/app/features/wallets/data/database/tables/transactions_table.d.dart';
import 'package:ion/app/features/wallets/data/database/wallets_database.m.steps.dart';
import 'package:ion/app/utils/directory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallets_database.m.g.dart';

@riverpod
WalletsDatabase walletsDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final appGroup = Platform.isIOS
      ? ref.watch(envProvider.notifier).get<String>(EnvVariable.FOUNDATION_APP_GROUP)
      : null;
  final database = WalletsDatabase(pubkey, appGroupId: appGroup);

  onLogout(ref, database.close);
  onUserSwitch(ref, database.close);

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
    NftsTable,
  ],
)
class WalletsDatabase extends _$WalletsDatabase {
  WalletsDatabase(
    this.pubkey, {
    this.appGroupId,
  }) : super(_openConnection(pubkey, appGroupId));

  final String pubkey;
  final String? appGroupId;

  @override
  int get schemaVersion => 20;

  /// Opens a connection to the database with the given pubkey
  /// Uses app group container for iOS extensions if appGroupId is provided
  static QueryExecutor _openConnection(String pubkey, String? appGroupId) {
    final databaseName = 'wallets_database_$pubkey';
    if (appGroupId == null) {
      return driftDatabase(
        name: databaseName,
        native: DriftNativeOptions(
          setup: (database) => database.execute(DatabaseConstants.journalModeWAL),
        ),
      );
    }

    return driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databasePath: () async =>
            getSharedDatabasePath(databaseName: databaseName, appGroupId: appGroupId),
        shareAcrossIsolates: true,
        setup: (database) => database.execute(DatabaseConstants.journalModeWAL),
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.createTable(schema.fundsRequestsTable);
        },
        from2To3: (m, schema) async {
          await m.addColumn(schema.networksTable, schema.networksTable.tier);
        },
        from3To4: (m, schema) async {
          await m.dropColumn(schema.transactionsTable, 'balance_before_transfer');
        },
        from4To5: (m, schema) async {
          await m.dropColumn(schema.fundsRequestsTable, 'is_pending');
          await m.addColumn(schema.fundsRequestsTable, schema.fundsRequestsTable.transactionId);
        },
        from5To6: (m, schema) async {
          await m.alterTable(
            TableMigration(transactionsTable),
          );
        },
        from6To7: (m, schema) async {
          const oldTransactionsTableName = 'transactions_table';
          await m.createTable(transactionsTable);

          await customStatement('''
          INSERT INTO ${transactionsTable.actualTableName} (
            wallet_view_id, 
            type, tx_hash, network_id, coin_id, sender_wallet_address, 
            receiver_wallet_address, id, fee, status, native_coin_id, 
            date_confirmed, date_requested, created_at_in_relay, user_pubkey, 
            asset_id, transferred_amount, transferred_amount_usd
          )
          SELECT 
            '', 
            type, tx_hash, network_id, coin_id, sender_wallet_address, 
            receiver_wallet_address, id, fee, status, native_coin_id, 
            date_confirmed, date_requested, created_at_in_relay, user_pubkey, 
            asset_id, transferred_amount, transferred_amount_usd
          FROM $oldTransactionsTableName;
          ''');

          await m.deleteTable(oldTransactionsTableName);
        },
        from7To8: (m, schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.transactionsTableV2.actualTableName,
            columnName: 'event_id',
          );
          if (!columnExists) {
            await m.addColumn(schema.transactionsTableV2, schema.transactionsTableV2.eventId);
          }
        },
        from8To9: (Migrator m, Schema9 schema) async {
          await m.alterTable(
            TableMigration(
              schema.coinsTable,
              columnTransformer: {
                schema.coinsTable.native: const Constant(false),
              },
              newColumns: [schema.coinsTable.native],
            ),
          );
        },
        from9To10: (Migrator m, Schema10 schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.coinsTable.actualTableName,
            columnName: 'prioritized',
          );
          if (!columnExists) {
            await m.addColumn(schema.coinsTable, schema.coinsTable.prioritized);
          }
        },
        from10To11: (m, schema) async {
          await m.alterTable(
            TableMigration(
              schema.coinsTable,
              columnTransformer: {
                schema.coinsTable.native: const Constant(false),
                schema.coinsTable.prioritized: const Constant(false),
              },
            ),
          );
        },
        from11To12: (m, schema) async {
          final isExternalHashColumnExists = await isColumnExists(
            tableName: schema.transactionsTableV2.actualTableName,
            columnName: 'external_hash',
          );
          if (!isExternalHashColumnExists) {
            await m.addColumn(schema.transactionsTableV2, schema.transactionsTableV2.externalHash);
          }
        },
        from12To13: (m, schema) async {
          final table = schema.fundsRequestsTable;
          await m.alterTable(
            TableMigration(
              table,
              columnTransformer: {
                table.createdAt: table.normalizedTimestamp(table.createdAt),
              },
            ),
          );
        },
        from13To14: (m, schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.fundsRequestsTable.actualTableName,
            columnName: 'deleted',
          );
          if (!columnExists) {
            await m.addColumn(schema.fundsRequestsTable, schema.fundsRequestsTable.deleted);
          }
        },
        from14To15: (m, schema) async {
          await m.createTable(transactionVisibilityStatusTable);
        },
        from15To16: (m, schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.transactionsTableV2.actualTableName,
            columnName: 'nft_identifier',
          );

          if (!columnExists) {
            await m.addColumn(schema.transactionsTableV2, schema.transactionsTableV2.nftIdentifier);
          }
        },
        from16To17: (m, schema) async {
          await customStatement('''
            INSERT OR REPLACE INTO transaction_visibility_status_table (tx_hash, wallet_view_id, status)
            SELECT DISTINCT tx_hash, wallet_view_id, 1
            FROM transactions_table_v2
            WHERE type = 'receive' AND coin_id IS NOT NULL
          ''');
        },
        from17To18: (m, schema) async {
          await m.createTable(schema.nftsTable);
        },
        from18To19: (m, schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.transactionsTableV2.actualTableName,
            columnName: 'memo',
          );
          if (!columnExists) {
            await m.addColumn(schema.transactionsTableV2, schema.transactionsTableV2.memo);
          }
        },
        from19To20: (Migrator m, Schema20 schema) async {
          final columnExists = await isColumnExists(
            tableName: schema.transactionsTableV2.actualTableName,
            columnName: 'asset_contract_address',
          );
          if (!columnExists) {
            await m.addColumn(
              schema.transactionsTableV2,
              schema.transactionsTableV2.assetContractAddress,
            );
          }
        },
      ),
    );
  }

  Future<bool> isColumnExists({required String tableName, required String columnName}) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.data['name'] == columnName);
  }
}
