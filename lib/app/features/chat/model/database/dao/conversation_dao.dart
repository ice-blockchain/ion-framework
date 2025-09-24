// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationDao conversationDao(Ref ref) => ConversationDao(ref.watch(chatDatabaseProvider));

@DriftAccessor(
  tables: [
    ConversationTable,
    EventMessageTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class ConversationDao extends DatabaseAccessor<ChatDatabase> with _$ConversationDaoMixin {
  ConversationDao(super.db);

  /// Adds events to database and creates conversations
  ///
  /// Creates conversations from [EventMessage] list by extracting tags,
  /// setting type, and batch inserting into conversation table
  ///
  /// Skips events without community ID. Uses insertOrIgnore mode.
  Future<void> add(List<EventMessage> events) async {
    final companions = await _createConversationCompanions(events);
    await _batchInsertConversations(companions);
  }

  Future<List<ConversationTableCompanion?>> _createConversationCompanions(
    List<EventMessage> events,
  ) async {
    return events.map(
      (event) {
        final tags = groupBy(event.tags, (tag) => tag[0]);
        final communityIdentifierValue = _getCommunityIdentifier(tags);

        if (communityIdentifierValue == null) {
          return null;
        }

        final subject = _getSubject(tags);
        final conversationType = _determineConversationType(event.kind, subject);

        return ConversationTableCompanion(
          id: Value(communityIdentifierValue),
          type: Value(conversationType),
          joinedAt: Value(event.createdAt),
        );
      },
    ).toList();
  }

  String? _getCommunityIdentifier(Map<String, List<List<String>>> tags) {
    return tags[ConversationIdentifier.tagName]
        ?.map(ConversationIdentifier.fromTag)
        .firstOrNull
        ?.value;
  }

  GroupSubject? _getSubject(Map<String, List<List<String>>> tags) {
    return tags[GroupSubject.tagName]?.map(GroupSubject.fromTag).firstOrNull;
  }

  ConversationType _determineConversationType(int kind, GroupSubject? subject) {
    if (kind == CommunityJoinEntity.kind) {
      return ConversationType.community;
    }
    return subject == null ? ConversationType.oneToOne : ConversationType.group;
  }

  Future<void> _batchInsertConversations(List<ConversationTableCompanion?> companions) async {
    await batch((b) {
      b.insertAll(
        conversationTable,
        companions.nonNulls,
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  ///
  /// Adds a community conversation to the database
  ///
  /// Takes a [CommunityDefinitionData] and inserts a new conversation into the database
  /// with the community's UUID as the ID, type set to [ConversationType.community],
  /// and the current date as the joinedAt timestamp
  ///
  Future<void> addCommunityConversation(String communityId) async {
    await into(conversationTable).insert(
      ConversationTableCompanion(
        id: Value(communityId),
        type: const Value(ConversationType.community),
        joinedAt: Value(DateTime.now().microsecondsSinceEpoch),
      ),
    );
  }

  /// Watch the list of conversations sorted by latest activity
  ///
  /// Returns a stream of [ConversationListItem] sorted by:
  /// - Latest message date if conversation has messages
  /// - Join date if conversation has no messages
  ///
  /// The list is sorted in descending order (newest first)

  Stream<List<ConversationListItem>> watch() {
    final query = select(conversationTable).join([
      leftOuterJoin(
        conversationMessageTable,
        conversationMessageTable.conversationId.equalsExp(conversationTable.id),
      ),
      leftOuterJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(
        notExistsQuery(
          select(messageStatusTable)
            ..where((tbl) => tbl.status.equals(MessageDeliveryStatus.deleted.index))
            ..where(
              (table) => table.messageEventReference
                  .equalsExp(conversationMessageTable.messageEventReference),
            ),
        ),
      )
      ..where(conversationTable.isHidden.equals(false))
      ..addColumns([eventMessageTable.createdAt.max()])
      ..groupBy([conversationTable.id])
      ..distinct;

    return query.watch().map((rows) {
      final sortedRows = rows
          .sortedBy<num>(
        (e) =>
            e.readTableOrNull(eventMessageTable)?.createdAt ??
            e.readTable(conversationTable).joinedAt,
      )
          .map((row) {
        return ConversationListItem(
          type: row.readTable(conversationTable).type,
          joinedAt: row.readTable(conversationTable).joinedAt,
          conversationId: row.readTable(conversationTable).id,
          isArchived: row.readTable(conversationTable).isArchived,
          latestMessage: row.readTableOrNull(eventMessageTable)?.toEventMessage(),
        );
      }).toList();

      return sortedRows.reversed.toList();
    });
  }

  ///
  /// Get the id of the conversation with the given receiver master pubkey
  /// Only searches for non-deleted conversations of type [ConversationType.oneToOne]
  ///
  Future<String?> getExistingConversationId(List<String> participantsMasterPubkeys) async {
    final query = select(conversationTable).join([
      innerJoin(
        conversationMessageTable,
        conversationMessageTable.conversationId.equalsExp(conversationTable.id),
      ),
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationTable.type.equals(ConversationType.oneToOne.index))
      ..where(conversationTable.isHidden.equals(false))
      ..where(conversationMessageTable.conversationId.equals(participantsMasterPubkeys.join()))
      ..where(
        eventMessageTable.kind.equals(ReplaceablePrivateDirectMessageEntity.kind),
      )
      ..orderBy([OrderingTerm.desc(eventMessageTable.createdAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return row.readTable(conversationTable).id;
  }

  Future<bool> checkIfConversationExists(String conversationId) async {
    final query = select(conversationTable)
      ..where((t) => t.id.equals(conversationId))
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null;
  }

  /// Set the archived status of a conversation
  ///
  /// Takes a conversation [conversationId] and an optional [isArchived] boolean parameter
  /// Updates the conversation's archived status in the database.
  ///
  Future<void> setArchived(List<String> conversationIds, {bool isArchived = true}) async {
    await (update(conversationTable)..where((t) => t.id.isIn(conversationIds)))
        .write(ConversationTableCompanion(isArchived: Value(isArchived)));
  }

  /// Update the archived status of a list of conversations
  ///
  /// Takes a list of [archivedConversationIds] and updates the archived status of all conversations.
  /// Conversations with IDs in the list will be marked as archived (isArchived = true).
  /// All other conversations will be marked as not archived (isArchived = false).
  ///
  Future<void> updateArchivedConversations(List<String> archivedConversationIds) async {
    await batch((b) {
      b
        ..update(
          conversationTable,
          const ConversationTableCompanion(isArchived: Value(true)),
          where: (t) => t.id.isIn(archivedConversationIds),
        )
        ..update(
          conversationTable,
          const ConversationTableCompanion(isArchived: Value(false)),
          where: (t) => t.id.isNotIn(archivedConversationIds),
        );
    });
  }

  Future<ConversationType?> getConversationType(String conversationId) async {
    final query = select(conversationTable)..where((t) => t.id.equals(conversationId));
    final row = await query.getSingleOrNull();
    return row?.type;
  }

  Future<List<String>> getConversationParticipants(String conversationId) async {
    final query = select(eventMessageTable).join([
      innerJoin(
        conversationMessageTable,
        conversationMessageTable.messageEventReference.equalsExp(eventMessageTable.eventReference),
      ),
    ])
      ..where(conversationMessageTable.conversationId.equals(conversationId))
      ..orderBy([OrderingTerm.desc(eventMessageTable.createdAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    final eventMessage = row?.readTable(eventMessageTable).toEventMessage();

    if (eventMessage != null) {
      final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage);
      return entity.allPubkeys;
    }

    return [];
  }

  Future<bool> checkAnotherUserDeletedConversation({
    required String masterPubkey,
    required String conversationId,
  }) async {
    // Check if conversation is already marked as deleted in conversationTable
    final conversation = await (select(conversationTable)
          ..where((t) => t.id.equals(conversationId))
          ..where((t) => t.isHidden.equals(true)))
        .getSingleOrNull();

    if (conversation != null) {
      return true;
    }

    // Check for kind 5 (deletion request) events from the specified masterPubkey
    final kind5Events = await (select(eventMessageTable)
          ..where((t) => t.kind.equals(5))
          ..where((t) => t.masterPubkey.equals(masterPubkey)))
        .get();

    for (final event in kind5Events) {
      final eventMessage = event.toEventMessage();
      // Assuming deletion request events have tags in the format [[ConversationIdentifier.tagName, conversationId], ...]
      final hasConversationTag = eventMessage.tags.any(
        (tag) =>
            tag.isNotEmpty &&
            tag[0] == ConversationIdentifier.tagName &&
            tag.length > 1 &&
            tag[1] == conversationId,
      );
      if (hasConversationTag) {
        // Check if there are newer messages for this conversation
        final latestMessage = await (select(eventMessageTable).join([
          innerJoin(
            conversationMessageTable,
            conversationMessageTable.messageEventReference
                .equalsExp(eventMessageTable.eventReference),
          ),
        ])
              ..where(conversationMessageTable.conversationId.equals(conversationId))
              ..where(eventMessageTable.createdAt.isBiggerThanValue(eventMessage.createdAt))
              ..limit(1))
            .getSingleOrNull();

        if (latestMessage == null) {
          return true;
        }
      }
    }

    return false;
  }

  Future<List<String>> getAllConversationsIds() async {
    final conversations = await select(conversationTable).get();
    return conversations.map((e) => e.id).toList();
  }

  Future<void> removeConversations({
    required EventMessage deleteRequest,
    required List<String> conversationIds,
    required EventMessageDao eventMessageDao,
  }) async {
    await eventMessageDao.add(deleteRequest);

    final messageEventReference = await (select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
          ..where(conversationMessageTable.conversationId.isIn(conversationIds))
          ..where(eventMessageTable.createdAt.isSmallerThanValue(deleteRequest.createdAt)))
        .map((row) => row.readTable(conversationMessageTable).messageEventReference)
        .get();

    await batch((b) {
      b.update(
        messageStatusTable,
        const MessageStatusTableCompanion(status: Value(MessageDeliveryStatus.deleted)),
        where: (table) => table.messageEventReference.isInValues(messageEventReference),
      );
    });

    await unhideConversations(conversationIds);
  }

  Future<void> hideConversations(List<String> conversationsId) async {
    await (update(conversationTable)..where((t) => t.id.isIn(conversationsId)))
        .write(const ConversationTableCompanion(isHidden: Value(true)));
  }

  Future<void> unhideConversations(List<String> conversationsId) async {
    await (update(conversationTable)..where((t) => t.id.isIn(conversationsId)))
        .write(const ConversationTableCompanion(isHidden: Value(false)));
  }
}
