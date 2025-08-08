// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

@riverpod
ConversationMessageReactionDao conversationMessageReactionDao(Ref ref) =>
    ConversationMessageReactionDao(ref.watch(eventMessagesDatabaseProvider));

@DriftAccessor(
  tables: [ReactionTable, ConversationMessageTable, EventMessageTable],
)
class ConversationMessageReactionDao extends DatabaseAccessor<EventMessagesDatabase>
    with _$ConversationMessageReactionDaoMixin {
  ConversationMessageReactionDao(super.db);

  Future<void> add({
    required EventMessage reactionEvent,
    required EventMessageDao eventMessageDao,
  }) async {
    final reactionEntity = PrivateMessageReactionEntity.fromEventMessage(reactionEvent);

    await eventMessageDao.add(reactionEvent);
    await into(reactionTable).insert(
      ReactionTableCompanion.insert(
        reactionEventReference: reactionEntity.toEventReference(),
        messageEventReference: reactionEntity.data.reference,
        masterPubkey: reactionEntity.masterPubkey,
        content: reactionEntity.data.content,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> remove({
    required ImmutableEventReference reactionEventReference,
  }) async {
    await (update(reactionTable)
          ..where((table) => table.reactionEventReference.equalsValue(reactionEventReference)))
        .write(
      const ReactionTableCompanion(isDeleted: Value(true)),
    );
  }

  Future<void> revertDeletedReaction({
    required ImmutableEventReference reactionEventReference,
  }) async {
    await (update(reactionTable)
          ..where((table) => table.reactionEventReference.equalsValue(reactionEventReference)))
        .write(
      const ReactionTableCompanion(isDeleted: Value(false)),
    );
  }

  Stream<List<MessageReactionGroup>> messageReactions(EventMessage kind14EventMessage) async* {
    final eventReference =
        ReplaceablePrivateDirectMessageEntity.fromEventMessage(kind14EventMessage)
            .toEventReference();

    final existingRows = (select(reactionTable)
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.messageEventReference.equalsValue(eventReference)))
        .watch();

    yield* existingRows.asyncMap((rows) async {
      final groupedReactions = <String, List<EventMessage>>{};

      for (final row in rows) {
        final eventMessageDataRow = await (select(db.eventMessageTable)
              ..where((table) => table.eventReference.equalsValue(row.reactionEventReference)))
            .getSingleOrNull();

        if (eventMessageDataRow != null) {
          if (!groupedReactions.containsKey(row.content)) {
            groupedReactions[row.content] = [];
          }
          groupedReactions[row.content]!.add(eventMessageDataRow.toEventMessage());
        }
      }

      return groupedReactions.entries.map((entry) {
        return MessageReactionGroup(
          emoji: entry.key,
          eventMessages: entry.value,
        );
      }).toList();
    });
  }

  Future<bool> isReactionExist({
    required EventReference messageEventReference,
    required String emoji,
    required String masterPubkey,
  }) async {
    final row = await (select(reactionTable)
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.messageEventReference.equalsValue(messageEventReference))
          ..where((table) => table.content.equals(emoji))
          ..where((table) => table.masterPubkey.equals(masterPubkey)))
        .get();

    return row.isNotEmpty;
  }

  Future<EventReference?> storyReaction(EventReference eventReference) async {
    final result = await (select(reactionTable)
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..limit(1))
        .getSingleOrNull();

    return result?.reactionEventReference;
  }

  Stream<String?> storyReactionContent(EventReference? eventReference) async* {
    if (eventReference == null) {
      yield null;
      return;
    }

    final stream = (select(reactionTable)
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.messageEventReference.equalsValue(eventReference)))
        .watchSingleOrNull()
        .map((row) => row?.content);

    await for (final value in stream) {
      yield value;
    }
  }
}
