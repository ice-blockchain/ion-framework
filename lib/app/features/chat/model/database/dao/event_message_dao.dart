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
      case EncryptedDirectMessageEntity.kind:
        eventReference = EncryptedDirectMessageEntity.fromEventMessage(event).toEventReference();
      case PrivateMessageReactionEntity.kind:
        eventReference = PrivateMessageReactionEntity.fromEventMessage(event).toEventReference();
      default:
        return;
    }

    final dbModel = event.toChatDbModel(eventReference);

    await into(db.eventMessageTable).insert(dbModel, mode: InsertMode.insertOrReplace);
  }

  Future<List<EventMessage>> search(String content) async {
    if (content.isEmpty) return [];

    final searchResults =
        await (select(db.eventMessageTable)..where((tbl) => tbl.content.like('%$content%'))).get();

    return searchResults.map((row) => row.toEventMessage()).toList();
  }

  Stream<List<EventMessage>> watchAllFiltered({
    String? contentKeyword,
    List<List<String>>? tags,
    List<int> kinds = const [],
  }) {
    final conditions = <Expression<bool>>[];

    if (kinds.isNotEmpty) {
      conditions.add(db.eventMessageTable.kind.isIn(kinds));
    }

    if (contentKeyword != null) {
      final q = '%${contentKeyword.toLowerCase()}%';
      conditions.add(db.eventMessageTable.content.lower().like(q));
    }

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        if (tag.isEmpty) {
          continue;
        } else if (tag.length == 1) {
          final tagName = tag[0];
          conditions.add(
            CustomExpression<bool>(
              '''EXISTS (SELECT 1 FROM json_each(tags) WHERE json_extract(value, '\$[0]') = '$tagName')''',
            ),
          );
        } else if (tag.length >= 2) {
          final tagName = tag[0];
          final tagValue = tag[1];
          conditions.add(
            CustomExpression<bool>(
              '''EXISTS (SELECT 1 FROM json_each(tags) WHERE json_extract(value, '\$[0]') = '$tagName' AND json_extract(value, '\$[1]') = '$tagValue')''',
            ),
          );
        }
      }
    }

    final query = select(db.eventMessageTable);

    if (conditions.isNotEmpty) {
      query.where((tbl) => conditions.reduce((prev, next) => prev & next));
    }

    final results =
        query.watch().distinct().map((rows) => rows.map((row) => row.toEventMessage()).toList());

    return results;
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
