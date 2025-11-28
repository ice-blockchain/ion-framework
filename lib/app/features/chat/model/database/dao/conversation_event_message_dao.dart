// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationEventMessageDao conversationEventMessageDao(Ref ref) =>
    ConversationEventMessageDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    EventMessageTable,
    ConversationMessageTable,
  ],
)
class ConversationEventMessageDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationEventMessageDaoMixin {
  ConversationEventMessageDao(super.db);

  /// Add an event message to the database and associate it with a conversation
  ///
  /// Takes an [EventMessage] and extracts the conversation ID from its tags.
  /// If a valid conversation ID is found:
  /// 1. Inserts/replaces the event message in the event_message table
  /// 2. Creates a mapping in the chat_message table between the conversation and event message
  ///
  /// The chat_message mapping is only inserted if it doesn't already exist.
  Future<void> add(EventMessage event) async {
    final conversationId =
        event.tags.firstWhere((tag) => tag[0] == ConversationIdentifier.tagName).lastOrNull;

    if (conversationId == null) {
      return;
    }

    final eventReference = ReplaceablePrivateDirectMessageEntity.fromEventMessage(event)
        .data
        .toReplaceableEventReference(event.masterPubkey);

    final dbModel = event.toChatDbModel(eventReference);

    if (await _isEventMessageNewer(eventReference, dbModel)) {
      await into(db.eventMessageTable).insert(
        dbModel,
        mode: InsertMode.insertOrReplace,
      );

      await into(db.conversationMessageTable).insert(
        ConversationMessageTableCompanion.insert(
          messageEventReference: eventReference,
          conversationId: conversationId,
          publishedAt: Value(event.publishedAt),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<bool> _isEventMessageNewer(
    EventReference eventReference,
    EventMessageDbModel newEvent,
  ) async {
    final existingEventMessage = await (select(eventMessageTable)
          ..where((t) => t.eventReference.equalsValue(eventReference))
          ..limit(1))
        .getSingleOrNull();

    if (existingEventMessage == null) {
      return true;
    }

    return newEvent.createdAt.toDateTime.isAfter(existingEventMessage.createdAt.toDateTime) ||
        newEvent.createdAt.toDateTime.isAtSameMomentAs(existingEventMessage.createdAt.toDateTime);
  }

  /// Get the creation date of the most recent event messages of specific kinds
  /// Returns null if no messages of those kinds exist
  Future<DateTime?> getLatestEventMessageDate(List<int> kinds) async {
    final query = select(eventMessageTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..where((t) => t.kind.isIn(kinds))
      ..limit(1);

    return (await query.getSingleOrNull())?.createdAt.toDateTime;
  }

  /// Get the creation date of the oldest event messages of specific kinds
  /// Returns null if no messages of those kinds exist
  Future<DateTime?> getEarliestEventMessageDate(List<int> kinds, {DateTime? after}) async {
    final query = select(eventMessageTable)..where((t) => t.kind.isIn(kinds));

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    query
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);

    return (await query.getSingleOrNull())?.createdAt.toDateTime;
  }
}
