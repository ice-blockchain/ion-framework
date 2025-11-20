// SPDX-License-Identifier: ice License 1.0

part of '../chat_database.m.dart';

@Riverpod(keepAlive: true)
ConversationDao conversationDao(Ref ref) => ConversationDao(
      ref.watch(chatDatabaseProvider),
      eventMessageDao: ref.watch(eventMessageDaoProvider),
      fileCacheService: ref.watch(ionConnectFileCacheServiceProvider),
    );

@DriftAccessor(
  tables: [
    ReactionTable,
    ConversationTable,
    EventMessageTable,
    MessageMediaTable,
    MessageStatusTable,
    ConversationMessageTable,
  ],
)
class ConversationDao extends DatabaseAccessor<ChatDatabase> with _$ConversationDaoMixin {
  ConversationDao(
    super.db, {
    required this.eventMessageDao,
    required this.fileCacheService,
  });

  final EventMessageDao eventMessageDao;
  final FileCacheService fileCacheService;

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

  /// Returns `true` if there is a kind 5 (deletion request) event newer than the given [entity]'s createdAt for the conversation,
  /// otherwise returns `false`.
  Future<bool> conversationIsNotDeleted(String conversationId, int createdAt) async {
    final query = select(eventMessageTable)
      ..where(
        (t) =>
            t.kind.equals(DeletionRequestEntity.kind) &
            t.tags.like('%["${ConversationIdentifier.tagName}","$conversationId"%') &
            t.createdAt.isBiggerThanValue(createdAt),
      )
      ..limit(1);

    final deleteEvent = await query.getSingleOrNull();

    return deleteEvent == null;
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
    final eventMessageTableName = eventMessageTable.actualTableName;
    final conversationTableName = conversationTable.actualTableName;
    final lastActivityExpr = CustomExpression<DateTime>(
      'COALESCE(MAX($eventMessageTableName.created_at), $conversationTableName.joined_at)',
    );

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
      ..where(conversationMessageTable.isDeleted.equals(false))
      ..where(conversationTable.isHidden.equals(false))
      ..addColumns([
        lastActivityExpr,
      ])
      ..groupBy([conversationTable.id])
      ..orderBy([
        OrderingTerm.desc(lastActivityExpr),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final conv = row.readTable(conversationTable);
        final event = row.readTableOrNull(eventMessageTable);

        return ConversationListItem(
          type: conv.type,
          joinedAt: conv.joinedAt,
          conversationId: conv.id,
          isArchived: conv.isArchived,
          latestMessage: event?.toEventMessage(),
        );
      }).toList();
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
          ..where((t) => t.isHidden.equals(true))
          ..limit(1))
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

  Future<void> removeConversationsFromDatabase({
    required int startingFrom,
    required List<String> conversationIds,
  }) async {
    // Get all message event references for the conversations before startingFrom
    final query = select(conversationMessageTable).join([
      innerJoin(
        eventMessageTable,
        eventMessageTable.eventReference.equalsExp(conversationMessageTable.messageEventReference),
      ),
    ])
      ..where(conversationMessageTable.conversationId.isIn(conversationIds))
      ..where(eventMessageTable.createdAt.isSmallerThanValue(startingFrom));

    final messageEventReferences = await query
        .map((row) => row.readTable(conversationMessageTable).messageEventReference)
        .get();

    // Find all medias that belong to these messages
    // and delete the files from storage
    final mediaQuery = select(messageMediaTable)
      ..where((t) => t.messageEventReference.isInValues(messageEventReferences));
    final medias = await mediaQuery.get();
    for (final media in medias) {
      if (media.remoteUrl?.isNotEmpty ?? false) {
        unawaited(fileCacheService.removeFile(media.remoteUrl!));
      }
    }

    final reactionEventReferences = await (select(reactionTable)
          ..where((t) => t.messageEventReference.isInValues(messageEventReferences)))
        .get()
        .then((value) => value.map((e) => e.reactionEventReference).toList());

    await batch((b) {
      // Remove statuses for these event messages
      b
        // Remove event messages
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(messageEventReferences),
        )
        // Remove reaction events
        ..deleteWhere(
          eventMessageTable,
          (table) => table.eventReference.isInValues(reactionEventReferences),
        )
        // Remove message media entries
        ..deleteWhere(
          messageMediaTable,
          (table) => table.messageEventReference.isInValues(messageEventReferences),
        )
        // Remove conversation messages
        ..deleteWhere(
          conversationMessageTable,
          (table) => table.messageEventReference.isInValues(messageEventReferences),
        )
        // Remove message statuses
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(messageEventReferences),
        )
        // Remove message reaction statuses
        ..deleteWhere(
          messageStatusTable,
          (table) => table.messageEventReference.isInValues(reactionEventReferences),
        )
        // Remove reactions
        ..deleteWhere(
          reactionTable,
          (table) => table.messageEventReference.isInValues(messageEventReferences),
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
