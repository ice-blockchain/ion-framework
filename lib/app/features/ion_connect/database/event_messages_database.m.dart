// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/community_join_data.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/model/group_subject.f.dart';
import 'package:ion/app/features/chat/model/message_reaction_group.f.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_modifier_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/converters/feed_type_converter.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/seen_events_table.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/seen_reposts_table.d.dart';
import 'package:ion/app/features/feed/data/database/following_feed_database/tables/user_fetch_states_table.d.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/account_notification_sync_state_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/comments_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/followers_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/likes_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/database/tables/subscribed_users_content_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/model/content_type.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/database/tables/event_messages_table.d.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_block/model/database/tables/block_event_table.d.dart';
import 'package:ion/app/features/user_block/model/database/tables/unblock_event_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_badge_info_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_delegation_table.d.dart';
import 'package:ion/app/features/user_profile/database/tables/user_metadata_table.d.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dao/conversation_dao.dart';
part 'dao/conversation_event_message_dao.dart';
part 'dao/conversation_message_dao.dart';
part 'dao/conversation_message_data_dao.dart';
part 'dao/conversation_message_reaction_dao.r.dart';
part 'dao/event_message_dao.dart';
part 'dao/event_messages_dao.m.dart';
part 'dao/message_media_dao.r.dart';
part 'event_messages_database.m.g.dart';
part 'tables/chat_message_table.dart';
part 'tables/conversation_table.dart';
part 'tables/event_message_table.dart';
part 'tables/message_media_table.dart';
part 'tables/message_status_table.dart';
part 'tables/reaction_table.dart';

@Riverpod(keepAlive: true)
EventMessagesDatabase eventMessagesDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = EventMessagesDatabase(pubkey);

  onLogout(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    EventMessagesTable,
    UserMetadataTable,
    UserDelegationTable,
    UserBadgeInfoTable,
    BlockEventTable,
    UnblockEventTable,
    SeenEventsTable,
    SeenRepostsTable,
    UserFetchStatesTable,
    CommentsTable,
    SubscribedUsersContentTable,
    LikesTable,
    FollowersTable,
    AccountNotificationSyncStateTable,
    ConversationTable,
    EventMessageTable,
    ConversationMessageTable,
    MessageStatusTable,
    ReactionTable,
    MessageMediaTable,
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
  },
)
class EventMessagesDatabase extends _$EventMessagesDatabase {
  EventMessagesDatabase(this.pubkey) : super(_openConnection(pubkey));

  final String pubkey;

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection(String pubkey) {
    return driftDatabase(name: 'event_messages_database_$pubkey');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      //TODO: remove
      beforeOpen: (openingDetails) async {
        final m = createMigrator(); // changed to this
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
          await m.createTable(table);
        }
      },
    );
  }
}
