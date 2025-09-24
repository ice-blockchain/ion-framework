// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationMessageDao conversationMessageDao(Ref ref) =>
    ConversationMessageDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    ConversationMessageTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationTable,
    ReactionTable,
  ],
)
class ConversationMessageDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationMessageDaoMixin {
  ConversationMessageDao(super.db);

  Stream<int> getUnreadMessagesCount({
    required String conversationId,
    required String currentUserMasterPubkey,
  }) {
    final query = select(conversationMessageTable).join([
      innerJoin(
        messageStatusTable,
        messageStatusTable.messageEventReference
            .equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..where(messageStatusTable.masterPubkey.equals(currentUserMasterPubkey))
      ..where(messageStatusTable.status.equals(MessageDeliveryStatus.received.index))
      ..groupBy([messageStatusTable.messageEventReference]);

    return query.watch().map((rows) => rows.length);
  }

  Stream<int> getAllUnreadMessagesCountInArchive(
    String currentUserMasterPubkey,
  ) {
    final query = select(messageStatusTable).join([
      innerJoin(
        conversationMessageTable,
        conversationMessageTable.messageEventReference
            .equalsExp(messageStatusTable.messageEventReference),
      ),
      innerJoin(
        conversationTable,
        conversationTable.id.equalsExp(conversationMessageTable.conversationId),
      ),
    ])
      ..where(conversationTable.isArchived.equals(true))
      ..where(messageStatusTable.masterPubkey.equals(currentUserMasterPubkey))
      ..where(messageStatusTable.status.equals(MessageDeliveryStatus.received.index))
      ..groupBy([messageStatusTable.messageEventReference]);

    return query.watch().map((rows) => rows.length);
  }

  Stream<int> getAllUnreadMessagesCount(
    String masterPubkey,
    List<String> mutedConversationIds,
  ) {
    final deletedRefs = selectOnly(messageStatusTable)
      ..addColumns([messageStatusTable.messageEventReference])
      ..where(messageStatusTable.status.equals(MessageDeliveryStatus.deleted.index));

    final query = select(messageStatusTable).join([
      innerJoin(
        conversationMessageTable,
        conversationMessageTable.messageEventReference
            .equalsExp(messageStatusTable.messageEventReference),
      ),
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(messageStatusTable.messageEventReference),
      ),
    ])
      ..where(
        conversationMessageTable.conversationId.isNotIn(mutedConversationIds),
      )
      ..where(messageStatusTable.status.equals(MessageDeliveryStatus.received.index))
      ..where(messageStatusTable.messageEventReference.isNotInQuery(deletedRefs))
      ..where(messageStatusTable.masterPubkey.equals(masterPubkey))
      ..groupBy([eventMessageTable.masterPubkey]);

    return query.watch().map((rows) {
      return rows.length;
    });
  }

  Stream<Map<DateTime, List<EventMessage>>> getMessages(String conversationId) {
    final query = select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..where(
        notExistsQuery(
          select(messageStatusTable)
            ..where((tbl) => tbl.status.equals(MessageDeliveryStatus.deleted.index))
            ..where(
              (table) => table.messageEventReference.equalsExp(eventMessageTable.eventReference),
            ),
        ),
      );

    return query.watch().map((List<TypedResult> rows) {
      final groupedMessages = <DateTime, List<EventMessage>>{};

      for (final row in rows) {
        final eventMessage = row.readTable(eventMessageTable).toEventMessage();

        final publishedAtDate = eventMessage.publishedAt.toDateTime;
        final dateKey = DateTime(
          publishedAtDate.year,
          publishedAtDate.month,
          publishedAtDate.day,
        );

        groupedMessages.putIfAbsent(dateKey, () => []).add(eventMessage);
      }

      // Sort all message lists after grouping is complete
      for (final messages in groupedMessages.values) {
        messages.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      }

      return groupedMessages;
    }).startWithStream(Stream.value(<DateTime, List<EventMessage>>{}));
  }

  Future<EventMessage> getEventMessage({required EventReference eventReference}) async {
    final message = await (select(eventMessageTable)
          ..where((table) => table.eventReference.equalsValue(eventReference)))
        .getSingle();

    return message.toEventMessage();
  }

  Stream<EventMessage?> watchEventMessage({required EventReference eventReference}) {
    final query = select(eventMessageTable).join([
      innerJoin(
        messageStatusTable,
        messageStatusTable.messageEventReference.equalsExp(eventMessageTable.eventReference),
      ),
    ])
      ..where(
        notExistsQuery(
          select(messageStatusTable)
            ..where((tbl) => tbl.status.equals(MessageDeliveryStatus.deleted.index))
            ..where(
              (table) => table.messageEventReference.equalsExp(eventMessageTable.eventReference),
            ),
        ),
      )
      ..where(eventMessageTable.eventReference.equalsValue(eventReference))
      ..groupBy([eventMessageTable.eventReference])
      ..distinct;

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return row.readTable(eventMessageTable).toEventMessage();
    });
  }

  Future<void> removeMessages({
    required Env env,
    required String masterPubkey,
    required String eventSignerPubkey,
    required List<EventReference> eventReferences,
  }) async {
    await _removeExpiredMessages(eventReferences, env);

    for (final eventReference in eventReferences) {
      final existingStatusRow = await (select(messageStatusTable)
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.pubkey.equals(eventSignerPubkey))
            ..where((table) => table.messageEventReference.equalsValue(eventReference))
            ..limit(1))
          .getSingleOrNull();

      if (existingStatusRow == null) {
        await into(messageStatusTable).insert(
          MessageStatusTableCompanion.insert(
            masterPubkey: masterPubkey,
            pubkey: eventSignerPubkey,
            messageEventReference: eventReference,
            status: MessageDeliveryStatus.deleted,
          ),
        );
        continue;
      }

      await (update(messageStatusTable)
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.pubkey.equals(eventSignerPubkey))
            ..where((table) => table.messageEventReference.equalsValue(eventReference)))
          .write(
        const MessageStatusTableCompanion(status: Value(MessageDeliveryStatus.deleted)),
      );
    }
  }

  Future<void> revertDeletedMessages({
    required Env env,
    required String masterPubkey,
    required String eventSignerPubkey,
    required List<EventReference> eventReferences,
  }) async {
    for (final eventReference in eventReferences) {
      final existingStatusRow = await (select(messageStatusTable)
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.pubkey.equals(eventSignerPubkey))
            ..where((table) => table.messageEventReference.equalsValue(eventReference))
            ..limit(1))
          .getSingleOrNull();

      if (existingStatusRow == null) {
        await into(messageStatusTable).insert(
          MessageStatusTableCompanion.insert(
            masterPubkey: masterPubkey,
            pubkey: eventSignerPubkey,
            messageEventReference: eventReference,
            status: MessageDeliveryStatus.read,
          ),
        );
        continue;
      }

      await (update(messageStatusTable)
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.pubkey.equals(eventSignerPubkey))
            ..where((table) => table.messageEventReference.equalsValue(eventReference)))
          .write(
        const MessageStatusTableCompanion(status: Value(MessageDeliveryStatus.read)),
      );
    }
  }

  Future<void> _removeExpiredMessages(List<EventReference> eventReferences, Env env) async {
    final expiration = env.get<int>(EnvVariable.GIFT_WRAP_EXPIRATION_HOURS);

    final expiredMessageEventReferences = await (select(eventMessageTable)
          ..where(
            (table) => table.createdAt.isSmallerThanValue(
              DateTime.now().subtract(Duration(hours: expiration)).microsecondsSinceEpoch,
            ),
          )
          ..where((table) => table.eventReference.isInValues(eventReferences)))
        .map((e) => e.eventReference)
        .get();

    await batch((b) {
      b
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(expiredMessageEventReferences),
        )
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(expiredMessageEventReferences),
        )
        ..deleteWhere(
          conversationMessageTable,
          (table) => table.messageEventReference.isInValues(expiredMessageEventReferences),
        )
        ..deleteWhere(
          reactionTable,
          (table) => table.messageEventReference.isInValues(expiredMessageEventReferences),
        );
    });
  }
}
