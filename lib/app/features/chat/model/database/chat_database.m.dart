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
import 'package:ion/app/extensions/map.dart';
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
      onUpgrade: (m, from, to) async {
        // Run migrations step by step
        if (from < 2) {
          final schema = Schema2(database: m.database);
          final migrator = Migrator(m.database, schema);
          await Future.wait(
            [
              migrator.alterTable(
                TableMigration(
                  schema.conversationTable,
                  columnTransformer: {
                    schema.conversationTable.joinedAt: schema.conversationTable.normalizedTimestamp(
                      schema.conversationTable.joinedAt,
                    ),
                  },
                ),
              ),
              migrator.alterTable(
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
          from = 2;
        }
        if (from < 3) {
          final schema = Schema3(database: m.database);
          final migrator = Migrator(m.database, schema);
          //  Rename "isDeleted" column from ConversationTable to "isHidden"
          await migrator.dropColumn(schema.conversationTable, 'is_deleted');
          await migrator.addColumn(schema.conversationTable, schema.conversationTable.isHidden);
          from = 3;
        }
        if (from < 4) {
          final schema = Schema4(database: m.database);
          final migrator = Migrator(m.database, schema);
          await migrator.createTable(schema.processedGiftWrapTable);
          from = 4;
        }
        if (from < 5) {
          // Add indexes to optimize queries
          await Future.wait([
            // Index for conversation_message joins
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_conversation_message_conversation_id '
              'ON conversation_message_table(conversation_id)',
            ),
            // Index for event_message joins
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_conversation_message_event_reference '
              'ON conversation_message_table(message_event_reference)',
            ),
            // Index for event_message ordering and filtering
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_event_message_created_at '
              'ON event_message_table(created_at)',
            ),
            // Index for event_message kind filtering
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_event_message_kind '
              'ON event_message_table(kind)',
            ),
            // Composite index for kind + created_at (for search queries)
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_event_message_kind_created_at '
              'ON event_message_table(kind, created_at DESC)',
            ),
            // Index for message_status deleted check
            m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_message_status_reference_status '
              'ON message_status_table(message_event_reference, status)',
            ),
          ]);
        }
      },
    );
  }
}
