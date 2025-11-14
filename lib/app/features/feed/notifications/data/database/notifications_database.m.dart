// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/database.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.steps.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/account_notification_sync_state_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/comments_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/followers_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/likes_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/mentions_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/subscribed_users_content_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/model/content_type.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_database.m.g.dart';

@Riverpod(keepAlive: true)
NotificationsDatabase notificationsDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = NotificationsDatabase(pubkey);

  onLogout(ref, database.close);
  onUserSwitch(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    CommentsTable,
    SubscribedUsersContentTable,
    LikesTable,
    FollowersTable,
    MentionsTable,
    AccountNotificationSyncStateTable,
  ],
  queries: {
    'aggregatedLikes': '''
      WITH DailyLikes AS (
          SELECT
              DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')) AS event_date,
              event_reference,
              pubkey,
              created_at,
              ROW_NUMBER() OVER (PARTITION BY DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')), event_reference 
                  ORDER BY created_at DESC) AS rn
          FROM
              likes_table
      )
      SELECT
          event_date,
          event_reference,
          MAX(created_at) AS last_created_at,
          GROUP_CONCAT(CASE WHEN rn <= 10 THEN pubkey END, ',') AS latest_pubkeys,
          COUNT(DISTINCT pubkey) AS unique_pubkey_count
      FROM
          DailyLikes
      GROUP BY
          event_date, event_reference
      ORDER BY
          last_created_at DESC, event_reference DESC;
    ''',
    'aggregatedFollowers': '''
      WITH DailyFollowers AS (
          SELECT
              DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')) AS event_date,
              pubkey,
              created_at,
              ROW_NUMBER() OVER (PARTITION BY DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')) 
                  ORDER BY created_at DESC) AS rn
          FROM
              followers_table
      )
      SELECT
          event_date,
          MAX(created_at) AS last_created_at,
          GROUP_CONCAT(CASE WHEN rn <= 10 THEN pubkey END, ',') AS latest_pubkeys,
          COUNT(DISTINCT pubkey) AS unique_pubkey_count
      FROM
          DailyFollowers
      GROUP BY
          event_date
      ORDER BY
          last_created_at DESC;
    ''',
    'aggregatedFollowersAfter': '''
      WITH DailyFollowers AS (
          SELECT
              DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')) AS event_date,
              pubkey,
              created_at,
              ROW_NUMBER() OVER (
                PARTITION BY DATE(datetime(
                  CASE 
                    WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                    ELSE created_at
                  END, 'unixepoch', 'localtime'))
                ORDER BY created_at DESC
                RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                EXCLUDE NO OTHERS
              ) AS rn
          FROM
              followers_table
      )
      SELECT
          event_date,
          MAX(created_at) AS last_created_at,
          GROUP_CONCAT(CASE WHEN rn <= 10 THEN pubkey END, ',') AS latest_pubkeys,
          COUNT(DISTINCT pubkey) AS unique_pubkey_count
      FROM
          DailyFollowers
      GROUP BY
          event_date
      HAVING last_created_at < ?
      ORDER BY
          last_created_at DESC
      LIMIT ?;
    ''',
    'aggregatedLikesAfter': '''
      WITH DailyLikes AS (
          SELECT
              DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')) AS event_date,
              event_reference,
              pubkey,
              created_at,
              ROW_NUMBER() OVER (PARTITION BY DATE(datetime(
                CASE 
                  WHEN LENGTH(created_at) > 13 THEN created_at / 1000000
                  ELSE created_at
                END, 'unixepoch', 'localtime')), event_reference 
                  ORDER BY created_at DESC) AS rn
          FROM
              likes_table
      )
      SELECT
          event_date,
          event_reference,
          MAX(created_at) AS last_created_at,
          GROUP_CONCAT(CASE WHEN rn <= 10 THEN pubkey END, ',') AS latest_pubkeys,
          COUNT(DISTINCT pubkey) AS unique_pubkey_count
      FROM
          DailyLikes
      GROUP BY
          event_date, event_reference
      HAVING last_created_at < ?
      ORDER BY
          last_created_at DESC, event_reference DESC
      LIMIT ?;
    ''',
  },
)
class NotificationsDatabase extends _$NotificationsDatabase {
  NotificationsDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await Future.wait([
            m.createTable(schema.followersTable),
            m.createTable(schema.likesTable),
          ]);
        },
        from2To3: (m, schema) async {
          await Future.wait(
            [
              m.alterTable(
                TableMigration(
                  schema.commentsTable,
                  columnTransformer: {
                    schema.commentsTable.createdAt: schema.commentsTable.normalizedTimestamp(
                      schema.commentsTable.createdAt,
                    ),
                  },
                ),
              ),
              m.alterTable(
                TableMigration(
                  schema.followersTable,
                  columnTransformer: {
                    schema.followersTable.createdAt: schema.followersTable.normalizedTimestamp(
                      schema.followersTable.createdAt,
                    ),
                  },
                ),
              ),
              m.alterTable(
                TableMigration(
                  schema.likesTable,
                  columnTransformer: {
                    schema.likesTable.createdAt: schema.likesTable.normalizedTimestamp(
                      schema.likesTable.createdAt,
                    ),
                  },
                ),
              ),
            ],
          );
        },
        from3To4: (m, schema) async {
          await Future.wait([
            m.createTable(schema.subscribedUsersContentTable),
            m.createTable(schema.accountNotificationSyncStateTable),
          ]);
        },
        from4To5: (m, schema) async {
          await m.database.customStatement('DROP TABLE IF EXISTS subscribed_users_content_table');
          await m.database.customStatement('DROP TABLE IF EXISTS content_table');
          await m.database
              .customStatement('DROP TABLE IF EXISTS account_notification_sync_state_table');

          await Future.wait([
            m.createTable(schema.accountNotificationSyncStateTable),
            m.createTable(schema.subscribedUsersContentTable),
          ]);
        },
        from5To6: (m, schema) async {
          await m.createTable(schema.mentionsTable);
        },
      ),
    );
  }

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(
      name: 'notifications_database_$pubkey',
      native: DriftNativeOptions(
        setup: (database) => database.execute(DatabaseConstants.journalModeWAL),
      ),
    );
  }
}
