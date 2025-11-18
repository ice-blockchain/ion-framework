// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/database.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/database.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/community_join_data.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_message_reaction_data.f.dart';
import 'package:ion/app/features/chat/extensions/event_message.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.steps.dart';
import 'package:ion/app/features/chat/model/group_subject.f.dart';
import 'package:ion/app/features/chat/model/message_reaction.f.dart';
import 'package:ion/app/features/chat/recent_chats/model/conversation_list_item.f.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_tags_converter.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/utils/directory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_database.m.g.dart';
part 'dao/conversation_dao.dart';
part 'dao/conversation_event_message_dao.dart';
part 'dao/conversation_message_dao.dart';
part 'dao/conversation_message_data_dao.dart';
part 'dao/conversation_message_reaction_dao.r.dart';
part 'dao/event_message_dao.dart';
part 'dao/message_media_dao.r.dart';
part 'dao/processed_gift_wrap_dao.dart';
part 'tables/chat_message_table.dart';
part 'tables/conversation_table.dart';
part 'tables/event_message_table.dart';
part 'tables/message_media_table.dart';
part 'tables/message_status_table.dart';
part 'tables/processed_gift_wrap_table.dart';
part 'tables/reaction_table.dart';

@Riverpod(keepAlive: true)
ChatDatabase chatDatabase(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final appGroup = Platform.isIOS
      ? ref.watch(envProvider.notifier).get<String>(EnvVariable.FOUNDATION_APP_GROUP)
      : null;
  final database = ChatDatabase(pubkey, appGroupId: appGroup);

  onLogout(ref, database.close);

  return database;
}

@DriftDatabase(
  tables: [
    ConversationTable,
    EventMessageTable,
    ConversationMessageTable,
    MessageStatusTable,
    ReactionTable,
    MessageMediaTable,
    ProcessedGiftWrapTable,
  ],
)
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase(
    this.pubkey, {
    this.appGroupId,
  }) : super(_openConnection(pubkey, appGroupId));

  final String pubkey;
  final String? appGroupId;

  @override
  int get schemaVersion => 5;

  static QueryExecutor _openConnection(String pubkey, String? appGroupId) {
    final databaseName = 'conversation_database_$pubkey';

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
        databasePath: () async => getSharedDatabasePath(
          databaseName: databaseName,
          appGroupId: appGroupId,
        ),
        shareAcrossIsolates: true,
        setup: (database) => database.execute(DatabaseConstants.journalModeWAL),
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        // Create composite index with DESC ordering (not supported by @TableIndex)
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_message_kind_created_at '
          'ON event_message_table(kind, created_at DESC)',
        );
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await Future.wait(
            [
              m.alterTable(
                TableMigration(
                  schema.conversationTable,
                  columnTransformer: {
                    schema.conversationTable.joinedAt: schema.conversationTable.normalizedTimestamp(
                      schema.conversationTable.joinedAt,
                    ),
                  },
                ),
              ),
              m.alterTable(
                TableMigration(
                  schema.eventMessageTable,
                  columnTransformer: {
                    schema.eventMessageTable.createdAt:
                        schema.eventMessageTable.normalizedTimestamp(
                      schema.eventMessageTable.createdAt,
                    ),
                  },
                ),
              ),
            ],
          );
        },
        from2To3: (Migrator m, Schema3 schema) async {
          //  Rename "isDeleted" column from ConversationTable to "isHidden"
          await m.dropColumn(schema.conversationTable, 'is_deleted');
          await m.addColumn(
            schema.conversationTable,
            schema.conversationTable.isHidden,
          );
        },
        from3To4: (Migrator m, Schema4 schema) async {
          await m.createTable(schema.processedGiftWrapTable);
        },
        from4To5: (Migrator m, Schema5 schema) async {
          await m.addColumn(
            schema.conversationMessageTable,
            schema.conversationMessageTable.isDeleted,
          );
          await m.addColumn(
            schema.conversationMessageTable,
            schema.conversationMessageTable.publishedAt,
          );

          await schema.database.customStatement(r'''
            UPDATE conversation_message_table
            SET published_at = (
              SELECT CAST(json_extract(tag.value, '$[1]') AS INTEGER)
              FROM event_message_table
              JOIN json_each(event_message_table.tags) AS tag
                ON json_extract(tag.value, '$[0]') = 'published_at'
              WHERE event_message_table.event_reference = conversation_message_table.message_event_reference
              LIMIT 1
            )
            WHERE EXISTS (
              SELECT 1
              FROM event_message_table
              JOIN json_each(event_message_table.tags) AS tag2
                ON json_extract(tag2.value, '$[0]') = 'published_at'
              WHERE event_message_table.event_reference = conversation_message_table.message_event_reference
            );
          ''');

          await schema.database.customStatement('''
            UPDATE conversation_message_table
            SET is_deleted = 1
            WHERE message_event_reference IN (
              SELECT message_event_reference
              FROM message_status_table
              WHERE status = 5
            );
          ''');
        },
      ),
    );
  }
}
