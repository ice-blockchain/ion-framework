// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

@Riverpod(keepAlive: true)
EventMessageDao eventMessageDao(Ref ref) =>
    EventMessageDao(ref.watch(eventMessagesDatabaseProvider));

@DriftAccessor(
  tables: [
    ReactionTable,
    ConversationTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class EventMessageDao extends DatabaseAccessor<EventMessagesDatabase> with _$EventMessageDaoMixin {
  EventMessageDao(super.db);

  Future<void> add(EventMessage event) async {
    final EventReference eventReference;
    switch (event.kind) {
      case DeletionRequestEntity.kind:
        eventReference = DeletionRequestEntity.fromEventMessage(event).toEventReference();
      case GenericRepostEntity.kind:
        eventReference = GenericRepostEntity.fromEventMessage(event).toEventReference();
      case ReplaceablePrivateDirectMessageEntity.kind:
        eventReference =
            ReplaceablePrivateDirectMessageEntity.fromEventMessage(event).toEventReference();
      case PrivateMessageReactionEntity.kind:
        eventReference = PrivateMessageReactionEntity.fromEventMessage(event).toEventReference();
      default:
        return;
    }

    final dbModel = event.toChatDbModel(eventReference);

    await into(db.eventMessageTable).insert(dbModel, mode: InsertMode.insertOrReplace);
  }

  Future<List<EventMessage>> search(String query) async {
    if (query.isEmpty) return [];

    final searchResults =
        await (select(db.eventMessageTable)..where((tbl) => tbl.content.like('%$query%'))).get();

    return searchResults.map((row) => row.toEventMessage()).toList();
  }

  Future<EventMessage> getByReference(EventReference eventReference) async {
    final result = await (select(db.eventMessageTable)
          ..where((table) => table.eventReference.equalsValue(eventReference)))
        .getSingle();
    return result.toEventMessage();
  }

  Future<EventMessage> getById(String id) async {
    final result =
        await (select(db.eventMessageTable)..where((table) => table.id.equals(id))).getSingle();
    return result.toEventMessage();
  }

  Future<void> deleteByEventReference(EventReference eventReference) async {
    await db.batch((batch) {
      batch
        ..deleteWhere(
          db.conversationMessageTable,
          (table) => table.messageEventReference.equalsValue(eventReference),
        )
        ..deleteWhere(
          db.messageMediaTable,
          (table) => table.messageEventReference.equalsValue(eventReference),
        )
        ..deleteWhere(
          db.messageStatusTable,
          (table) => table.messageEventReference.equalsValue(eventReference),
        )
        ..deleteWhere(
          db.reactionTable,
          (table) => table.messageEventReference.equalsValue(eventReference),
        )
        ..deleteWhere(
          db.eventMessageTable,
          (table) => table.eventReference.equalsValue(eventReference),
        );
    });
  }
}
