// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
EventMessageDao eventMessageDao(Ref ref) => EventMessageDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    ReactionTable,
    ConversationTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class EventMessageDao extends DatabaseAccessor<ChatDatabase> with _$EventMessageDaoMixin {
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

    final deletedMessagesSubquery = selectOnly(db.messageStatusTable)
      ..addColumns([db.messageStatusTable.messageEventReference])
      ..where(db.messageStatusTable.status.equals(MessageDeliveryStatus.deleted.index));

    final queryBuilder = select(db.eventMessageTable).join([
      innerJoin(
        db.conversationMessageTable,
        db.conversationMessageTable.messageEventReference
            .equalsExp(db.eventMessageTable.eventReference),
      ),
    ])
      ..where(db.eventMessageTable.kind.equals(ReplaceablePrivateDirectMessageEntity.kind))
      ..where(db.eventMessageTable.content.lower().like('%${query.toLowerCase()}%'))
      ..where(
        db.eventMessageTable.eventReference.isNotInQuery(deletedMessagesSubquery),
      )
      ..orderBy([
        OrderingTerm.desc(db.eventMessageTable.createdAt),
      ]);

    final searchResults = await queryBuilder.get();

    return searchResults
        .map((row) => row.readTable(db.eventMessageTable).toEventMessage())
        .toList();
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
