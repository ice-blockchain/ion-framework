// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationMessageDao conversationMessageDao(Ref ref) => ConversationMessageDao(
      ref.watch(chatDatabaseProvider),
      masterPubkey: ref.watch(currentPubkeySelectorProvider),
      fileCacheService: ref.watch(ionConnectFileCacheServiceProvider),
      eventSigner: ref.watch(currentUserIonConnectEventSignerProvider).valueOrNull,
    );

@DriftAccessor(
  tables: [
    ReactionTable,
    MessageMediaTable,
    ConversationTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class ConversationMessageDao extends DatabaseAccessor<ChatDatabase>
    with _$ConversationMessageDaoMixin {
  ConversationMessageDao(
    super.db, {
    required this.eventSigner,
    required this.masterPubkey,
    required this.fileCacheService,
  });

  final String? masterPubkey;
  final EventSigner? eventSigner;
  final FileCacheService fileCacheService;

  /// Returns `true` if there is a kind 5 (deletion request) event newer than the given [entity]'s createdAt for the message,
  /// otherwise returns `false`.
  Future<bool> messageIsNotDeleted(EventReference eventReference) async {
    final query = select(eventMessageTable)
      ..where(
        (t) =>
            t.kind.equals(DeletionRequestEntity.kind) &
            t.tags.like(
              '%["${ReplaceableEventReference.tagName}","$eventReference"%',
            ),
      )
      ..limit(1);

    final deleteEvent = await query.getSingleOrNull();

    return deleteEvent == null;
  }

  Stream<int> getUnreadMessagesCount({
    required String conversationId,
    required String currentUserMasterPubkey,
  }) {
    final countExp = conversationMessageTable.messageEventReference.count();

    final query = selectOnly(conversationMessageTable)
      ..addColumns([countExp])
      ..join([
        innerJoin(
          messageStatusTable,
          messageStatusTable.messageEventReference
              .equalsExp(conversationMessageTable.messageEventReference),
        ),
      ])
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..where(messageStatusTable.masterPubkey.equals(currentUserMasterPubkey))
      ..where(
        messageStatusTable.status.equals(MessageDeliveryStatus.received.index),
      );

    return query.watchSingle().map((row) => row.read(countExp) ?? 0).distinct();
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
      ..where(
        messageStatusTable.status.equals(MessageDeliveryStatus.received.index),
      )
      ..groupBy([messageStatusTable.messageEventReference]);

    return query.watch().map((rows) => rows.length).distinct();
  }

  Stream<int> getAllUnreadMessagesCount(
    String masterPubkey,
    List<String> mutedConversationIds,
  ) {
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
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(
        conversationMessageTable.conversationId.isNotIn(mutedConversationIds),
      )
      ..where(
        messageStatusTable.status.equals(MessageDeliveryStatus.received.index),
      )
      ..where(messageStatusTable.masterPubkey.equals(masterPubkey))
      ..groupBy([eventMessageTable.masterPubkey]);

    return query.watch().map((rows) => rows.length).distinct();
  }

  Stream<List<EventMessage>> getMessages(
    String conversationId, {
    int? limit,
    int? since,
  }) {
    final query = select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..orderBy([OrderingTerm.desc(conversationMessageTable.publishedAt)]);

    if (since != null) {
      query.where(
        conversationMessageTable.publishedAt.isSmallerThanValue(since),
      );
    }

    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().asyncMap((List<TypedResult> rows) async {
      return rows.map((row) => row.readTable(eventMessageTable).toEventMessage()).toList();
    });
  }

  Stream<List<EventMessage>> watchTail(
    String conversationId, {
    required int limit,
  }) {
    final query = select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..orderBy([OrderingTerm.desc(conversationMessageTable.publishedAt)])
      ..limit(limit);

    return query.watch().asyncMap((List<TypedResult> rows) async {
      return rows.map((row) => row.readTable(eventMessageTable).toEventMessage()).toList();
    });
  }

  Future<List<EventMessage>> fetchPageBefore({
    required String conversationId,
    required int beforePublishedAt,
    required int limit,
  }) async {
    final query = select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..where(
        conversationMessageTable.publishedAt.isSmallerThanValue(beforePublishedAt),
      )
      ..orderBy([OrderingTerm.desc(conversationMessageTable.publishedAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) => row.readTable(eventMessageTable).toEventMessage()).toList();
  }

  Stream<EventMessage?> watchEventMessage({
    required EventReference eventReference,
  }) {
    final query = select(eventMessageTable).join([
      innerJoin(
        messageStatusTable,
        messageStatusTable.messageEventReference.equalsExp(eventMessageTable.eventReference),
      ),
      innerJoin(
        conversationMessageTable,
        conversationMessageTable.messageEventReference.equalsExp(eventMessageTable.eventReference),
      ),
    ])
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(eventMessageTable.eventReference.equalsValue(eventReference))
      ..groupBy([eventMessageTable.eventReference])
      ..distinct;

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return row.readTable(eventMessageTable).toEventMessage();
    }).distinct();
  }

  Future<void> removeMessagesFromDatabase(
    List<EventReference> eventReferences,
  ) async {
    // Find all medias that belong to these event messages and delete the files from storage
    final mediaQuery = select(messageMediaTable)
      ..where((t) => t.messageEventReference.isInValues(eventReferences));
    final medias = await mediaQuery.get();
    for (final media in medias) {
      if (media.remoteUrl?.isNotEmpty ?? false) {
        unawaited(fileCacheService.removeFile(media.remoteUrl!));
      }
    }

    final reactionEventReferences = await (select(reactionTable)
          ..where((t) => t.messageEventReference.isInValues(eventReferences)))
        .get()
        .then((value) => value.map((e) => e.reactionEventReference).toList());

    await batch((b) {
      // Remove event messages
      b
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(eventReferences),
        )
        // Remove reaction events
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(reactionEventReferences),
        )
        // Remove message media entries
        ..deleteWhere(
          messageMediaTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        )
        // Remove conversation messages
        ..deleteWhere(
          conversationMessageTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        )
        // Remove message statuses
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        )
        // Remove message reaction statuses
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(reactionEventReferences),
        )
        // Remove reactions
        ..deleteWhere(
          reactionTable,
          (table) => table.messageEventReference.isInValues(eventReferences),
        );
    });
  }

  Future<void> hideConversationMessages(
    List<EventReference> eventReferences,
  ) async {
    if (eventSigner == null || masterPubkey == null) {
      return;
    }

    await hideMessages(
      masterPubkey: masterPubkey!,
      eventReferences: eventReferences,
      eventSignerPubkey: eventSigner!.publicKey,
    );
  }

  Future<void> unhideConversationMessages(
    List<EventReference> eventReferences,
  ) async {
    if (eventSigner == null || masterPubkey == null) {
      return;
    }
    await unhideMessages(
      masterPubkey: masterPubkey!,
      eventReferences: eventReferences,
      eventSignerPubkey: eventSigner!.publicKey,
    );
  }

  Future<void> hideMessages({
    required String masterPubkey,
    required String eventSignerPubkey,
    required List<EventReference> eventReferences,
  }) async {
    for (final eventReference in eventReferences) {
      unawaited(
        (update(conversationMessageTable)
              ..where(
                (table) => table.messageEventReference.equalsValue(eventReference),
              ))
            .write(
          const ConversationMessageTableCompanion(isDeleted: Value(true)),
        ),
      );
    }
  }

  Future<void> unhideMessages({
    required String masterPubkey,
    required String eventSignerPubkey,
    required List<EventReference> eventReferences,
  }) async {
    for (final eventReference in eventReferences) {
      final existingStatusRow = await (select(messageStatusTable)
            ..where((table) => table.masterPubkey.equals(masterPubkey))
            ..where((table) => table.pubkey.equals(eventSignerPubkey))
            ..where(
              (table) => table.messageEventReference.equalsValue(eventReference),
            )
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
            ..where(
              (table) => table.messageEventReference.equalsValue(eventReference),
            ))
          .write(
        const MessageStatusTableCompanion(
          status: Value(MessageDeliveryStatus.read),
        ),
      );
    }
  }
}
