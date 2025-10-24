// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_modifier_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_type_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/following_feed_database.m.steps.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/seen_events_table.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/seen_reposts_table.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/user_fetch_states_table.d.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/utils/database_isolate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'following_feed_database.m.g.dart';

@Riverpod(keepAlive: true)
FollowingFeedDatabase followingFeedDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = FollowingFeedDatabase(pubkey);

  onLogout(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    SeenEventsTable,
    SeenRepostsTable,
    UserFetchStatesTable,
  ],
  queries: {
    'getEventCreatedAts': '''
      SELECT pubkey, created_at
        FROM (
          SELECT
            pubkey,
            created_at,
            ROW_NUMBER() OVER (
              PARTITION BY pubkey
              ORDER BY created_at DESC
            ) as rn
          FROM seen_events_table
        )
        WHERE rn <= :limit
    ''',
  },
)
class FollowingFeedDatabase extends _$FollowingFeedDatabase {
  FollowingFeedDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.createTable(schema.seenRepostsTable);
        },
        from2To3: (m, schema) async {
          // Migrating from a nullable to a non-nullable column (feedModifier)
          await m.deleteTable('seen_events_table');
          await m.createTable(schema.seenEventsTable);
          await m.createTable(schema.userFetchStatesTable);
        },
        from3To4: (Migrator m, Schema4 schema) async {
          // Remove lastContentTime column from userFetchStatesTable
          await m.alterTable(
            TableMigration(
              schema.userFetchStatesTable,
              columnTransformer: {
                // Remove the column by not including it in the transformer
                // No mapping for 'lastContentTime'
              },
            ),
          );
        },
      ),
    );
  }

  static QueryExecutor _openConnection(String pubkey) {
    return createDatabaseExecutorWithManualIsolate(
      databaseName: 'following_feed_database_$pubkey',
      setupCallback: (database) => database.execute(DatabaseConstants.journalModeWAL),
    );
  }
}
