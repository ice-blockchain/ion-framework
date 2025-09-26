// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
import 'package:ion/app/utils/directory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'chat_database.m.g.dart';
part 'dao/conversation_dao.dart';
part 'dao/conversation_event_message_dao.dart';
part 'dao/conversation_message_dao.dart';
part 'dao/conversation_message_data_dao.dart';
part 'dao/conversation_message_reaction_dao.r.dart';
part 'dao/event_message_dao.dart';
part 'dao/message_media_dao.r.dart';
part 'tables/chat_message_table.dart';
part 'tables/conversation_table.dart';
part 'tables/event_message_table.dart';
part 'tables/message_media_table.dart';
part 'tables/message_status_table.dart';
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
  int get schemaVersion => 3;

  static QueryExecutor _openConnection(String pubkey, String? appGroupId) {
    final databaseName = 'conversation_database_$pubkey';

    if (appGroupId == null) {
      return driftDatabase(name: databaseName);
    }

    return driftDatabase(
      name: databaseName,
      native: DriftNativeOptions(
        databasePath: () async =>
            getSharedDatabasePath(databaseName: databaseName, appGroupId: appGroupId),
        shareAcrossIsolates: true,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
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
          await m.addColumn(schema.conversationTable, schema.conversationTable.isHidden);
        },
      ),
    );
  }
}
