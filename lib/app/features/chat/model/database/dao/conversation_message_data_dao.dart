// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationMessageDataDao conversationMessageDataDao(Ref ref) =>
    ConversationMessageDataDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [MessageStatusTable, EventMessageTable, ConversationMessageTable],
)
class ConversationMessageDataDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationMessageDataDaoMixin {
  ConversationMessageDataDao(super.db);

  Future<void> addOrUpdateStatus({
    required String pubkey,
    required String masterPubkey,
    required MessageDeliveryStatus status,
    required EventReference messageEventReference,
    DateTime? updateAllBefore,
  }) async {
    if (updateAllBefore != null && status == MessageDeliveryStatus.read) {
      final conversationId = await (select(conversationMessageTable)
            ..where(
              (table) => table.messageEventReference.equalsValue(messageEventReference),
            )
            ..limit(1))
          .map((row) => row.conversationId)
          .getSingleOrNull();

      if (conversationId == null) {
        return;
      }

      // Mark all previous received messages as read prior to the given date
      final unreadResults = await (select(messageStatusTable).join([
        innerJoin(
          eventMessageTable,
          eventMessageTable.eventReference.equalsExp(messageStatusTable.messageEventReference),
        ),
        innerJoin(
          conversationMessageTable,
          conversationMessageTable.messageEventReference
              .equalsExp(messageStatusTable.messageEventReference),
        ),
      ])
            ..where(
              eventMessageTable.createdAt
                  .isSmallerOrEqualValue(updateAllBefore.microsecondsSinceEpoch),
            )
            ..where(messageStatusTable.masterPubkey.equals(masterPubkey))
            ..where(messageStatusTable.status.equals(MessageDeliveryStatus.received.index))
            ..where(conversationMessageTable.conversationId.equals(conversationId)))
          .map((row) => row.readTable(messageStatusTable))
          .get();

      // Batch update the status of all previous messages to read
      await batch((batch) async {
        for (final row in unreadResults) {
          batch.update(
            messageStatusTable,
            const MessageStatusTableCompanion(status: Value(MessageDeliveryStatus.read)),
            where: (table) => table.id.equals(row.id),
          );
        }
      });
    } else {
      // Fetch the existing status for the given pubkey and eventReference
      final existingStatus = await (select(messageStatusTable)
            ..where((table) => table.pubkey.equals(pubkey))
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.messageEventReference.equalsValue(messageEventReference))
            ..limit(1))
          .getSingleOrNull();

      if (existingStatus == null) {
        // Insert a new row if no existing status is found
        await into(messageStatusTable).insert(
          MessageStatusTableCompanion.insert(
            status: status,
            pubkey: pubkey,
            masterPubkey: masterPubkey,
            messageEventReference: messageEventReference,
          ),
        );
      } else if (status.index > existingStatus.status.index) {
        // Update the row if the new status has a higher priority
        await (update(messageStatusTable)
              ..where((table) => table.pubkey.equals(pubkey))
              ..where((table) => table.messageEventReference.equalsValue(messageEventReference))
              ..where((table) => table.masterPubkey.equals(masterPubkey)))
            .write(
          MessageStatusTableCompanion(
            status: Value(status),
          ),
        );
      }
    }
  }

  Stream<MessageDeliveryStatus> messageStatus({
    required EventReference eventReference,
    required String currentUserMasterPubkey,
  }) {
    return (select(messageStatusTable)
          ..where((table) => table.messageEventReference.equalsValue(eventReference)))
        .watch()
        .map((rows) {
      // If any of the rows are deleted, we consider the message as deleted
      if (rows.any((row) => row.status == MessageDeliveryStatus.deleted)) {
        return MessageDeliveryStatus.deleted;
      } else
      // Check if any of the rows failed (message is not sent, only local copy is
      // written to the database)
      if (rows.any((row) => row.status == MessageDeliveryStatus.failed)) {
        return MessageDeliveryStatus.failed;
      } else
      // Check if any received user device have read status which we consider as read
      if (rows.any(
        (row) =>
            row.status == MessageDeliveryStatus.read && row.masterPubkey != currentUserMasterPubkey,
      )) {
        return MessageDeliveryStatus.read;
      } else
      // Check if any received user device have received status which we consider as received
      if (rows.any(
        (row) =>
            row.status.index == MessageDeliveryStatus.received.index &&
            row.masterPubkey != currentUserMasterPubkey,
      )) {
        return MessageDeliveryStatus.received;
      } else
      // Check if any received user device have higher status then created
      if (rows.any(
        (row) =>
            row.status.index == MessageDeliveryStatus.sent.index &&
            row.masterPubkey != currentUserMasterPubkey,
      )) {
        return MessageDeliveryStatus.sent;
      }
      return MessageDeliveryStatus.created;
    }).distinct();
  }

  Future<Map<String, List<String>>> getFailedParticipants({
    required EventReference eventReference,
  }) async {
    final existingRows = await (select(messageStatusTable)
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..where((table) => table.status.equals(MessageDeliveryStatus.failed.index)))
        .get();

    final groupedByMasterPubkey = existingRows.groupListsBy((row) => row.masterPubkey).map(
          (masterPubkey, rows) => MapEntry(masterPubkey, rows.map((row) => row.pubkey).toList()),
        );

    return groupedByMasterPubkey;
  }

  Future<MessageDeliveryStatus?> checkMessageStatus({
    required String masterPubkey,
    required EventReference eventReference,
  }) async {
    final existingDeviceStatuses = await (select(messageStatusTable)
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..where((table) => table.masterPubkey.equals(masterPubkey)))
        .get();

    return existingDeviceStatuses.isNotEmpty
        ? existingDeviceStatuses
            .map((row) => row.status)
            .reduce((a, b) => a.index > b.index ? a : b)
        : null;
  }

  Future<void> reinitializeFailedStatus({
    required EventReference eventReference,
  }) async {
    await (update(messageStatusTable)
          ..where((table) => table.messageEventReference.equalsValue(eventReference))
          ..where((table) => table.status.equals(MessageDeliveryStatus.failed.index)))
        .write(
      const MessageStatusTableCompanion(
        status: Value(MessageDeliveryStatus.created),
      ),
    );
  }
}

enum MessageDeliveryStatus {
  created,
  failed,
  sent,
  received,
  read,
  deleted;
}
