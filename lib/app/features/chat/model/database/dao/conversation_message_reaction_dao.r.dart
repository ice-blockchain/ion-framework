// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@riverpod
ConversationMessageReactionDao conversationMessageReactionDao(Ref ref) =>
    ConversationMessageReactionDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    ReactionTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class ConversationMessageReactionDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationMessageReactionDaoMixin {
  ConversationMessageReactionDao(super.db);

  /// Returns `true` if there is a kind 5 (deletion request) event newer than the given [reactionEntity]'s createdAt for the reaction,
  /// otherwise returns `false`.
  Future<bool> reactionIsNotDeleted(PrivateMessageReactionEntity reactionEntity) async {
    final query = select(eventMessageTable)
      ..where(
        (t) =>
            t.kind.equals(DeletionRequestEntity.kind) &
            t.tags.like(
              '%["${ImmutableEventReference.tagName}","${reactionEntity.toEventReference()}"%',
            ) &
            t.tags.like('%["k","${PrivateMessageReactionEntity.kind}"%'),
      )
      ..limit(1);

    final deleteEvent = await query.getSingleOrNull();

    return deleteEvent == null;
  }

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

  Future<void> removeReactionsFromDatabase(List<ImmutableEventReference> eventReferences) async {
    await batch((b) {
      // Remove reactions from event messages table
      b
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(eventReferences),
        )
        // Remove message reaction statuses
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        )
        // Remove reactions
        ..deleteWhere(
          reactionTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        );
    });
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
    }).distinct((l1, l2) => l1.equalsDeep(l2));
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
        .map((row) => row?.content)
        .distinct();

    await for (final value in stream) {
      yield value;
    }
  }
}
