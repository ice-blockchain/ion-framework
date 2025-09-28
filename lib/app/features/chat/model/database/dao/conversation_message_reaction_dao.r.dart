// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@riverpod
ConversationMessageReactionDao conversationMessageReactionDao(Ref ref) =>
    ConversationMessageReactionDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [ReactionTable, ConversationMessageTable, EventMessageTable],
)
class ConversationMessageReactionDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationMessageReactionDaoMixin {
  ConversationMessageReactionDao(super.db);

  Future<void> add({
    required EventMessage reactionEvent,
    required EventMessageDao eventMessageDao,
  }) async {
    final reactionEntity = PrivateMessageReactionEntity.fromEventMessage(reactionEvent);

    await eventMessageDao.add(reactionEvent, wrapId: null);
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

  Stream<List<MessageReaction>> messageReactions(EventReference eventReference) async* {
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
        return MessageReaction(
          emoji: entry.key,
          masterPubkeys: entry.value.map((e) => e.masterPubkey).toSet().toList(),
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

  Future<EventReference?> getStoryReaction(EventReference eventReference) async {
    final result = await (select(reactionTable)
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..limit(1))
        .getSingleOrNull();

    return result?.reactionEventReference;
  }

  Future<EventReference?> getUserReactionReference({
    required String emoji,
    required String masterPubkey,
    required EventReference eventReference,
  }) async {
    final result = await (select(reactionTable)
          ..where((table) => table.content.equals(emoji))
          ..where((table) => table.isDeleted.equals(false))
          ..where((table) => table.masterPubkey.equals(masterPubkey))
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
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row?.content);

    await for (final value in stream) {
      yield value;
    }
  }
}
