// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_block/extensions/event_message.dart';
import 'package:ion/app/features/user_block/model/database/tables/block_event_table.d.dart';
import 'package:ion/app/features/user_block/model/database/tables/unblock_event_table.d.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'block_event_dao.m.g.dart';

@riverpod
BlockEventDao blockEventDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return BlockEventDao(ref.watch(eventMessagesDatabaseProvider));
}

@DriftAccessor(tables: [BlockEventTable, UnblockEventTable])
class BlockEventDao extends DatabaseAccessor<EventMessagesDatabase> with _$BlockEventDaoMixin {
  BlockEventDao(super.db);

  Future<void> add(EventMessage event) async {
    if (event.kind != BlockedUserEntity.kind) return;

    final eventReference = BlockedUserEntity.fromEventMessage(event).toEventReference();
    final dbModel = event.toBlockEventDbModel(eventReference);

    await into(db.blockEventTable).insert(dbModel, mode: InsertMode.insertOrReplace);
  }

  Future<List<EventReference>> getBlockEventReferences({
    required String currentUserMasterPubkey,
    required String blockedUserMasterPubkey,
  }) async {
    final blockEvents = await getBlockEvents(currentUserMasterPubkey);

    return blockEvents
        .map(BlockedUserEntity.fromEventMessage)
        .where((entity) => entity.data.blockedMasterPubkeys.contains(blockedUserMasterPubkey))
        .map((entity) => entity.toEventReference())
        .toList();
  }

  Future<DateTime?> getLatestBlockEventDate() async {
    final query = select(blockEventTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row?.createdAt.toDateTime;
  }

  Future<DateTime?> getEarliestBlockEventDate({DateTime? after}) async {
    final query = select(blockEventTable);

    if (after != null) {
      query.where((t) => t.createdAt.isBiggerThanValue(after.microsecondsSinceEpoch));
    }

    query
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row?.createdAt.toDateTime;
  }

  // Return only blocked events that are not deleted (not unblocked).
  JoinedSelectStatement<HasResultSet, dynamic> _blockedUserEventsQuery(
    String currentUserMasterPubkey,
  ) {
    return select(db.blockEventTable).join([
      leftOuterJoin(
        db.unblockEventTable,
        db.unblockEventTable.eventReference.equalsExp(db.blockEventTable.eventReference),
      ),
    ])
      ..where(db.blockEventTable.masterPubkey.equals(currentUserMasterPubkey))
      ..where(db.unblockEventTable.eventReference.isNull());
  }

  Future<List<EventMessage>> getBlockEvents(String currentUserMasterPubkey) async {
    final result = await _blockedUserEventsQuery(currentUserMasterPubkey).get();
    return result.map((row) => row.readTable(db.blockEventTable).toEventMessage()).toList();
  }

  Stream<List<EventMessage>> watchBlockedUsersEvents(String currentUserMasterPubkey) {
    return _blockedUserEventsQuery(currentUserMasterPubkey).watch().map(
          (rows) => rows.map((row) => row.readTable(db.blockEventTable).toEventMessage()).toList(),
        );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _blockedByUsersQuery(
    String currentUserMasterPubkey,
  ) {
    return select(db.blockEventTable).join([
      leftOuterJoin(
        db.unblockEventTable,
        db.unblockEventTable.eventReference.equalsExp(db.blockEventTable.eventReference),
      ),
    ])
      ..where(db.blockEventTable.masterPubkey.isNotValue(currentUserMasterPubkey))
      ..where(db.unblockEventTable.eventReference.isNull());
  }

  Future<List<EventMessage>> getBlockedByUsersEvents(String currentUserMasterPubkey) async {
    final result = await _blockedByUsersQuery(currentUserMasterPubkey).get();
    return result.map((row) => row.readTable(db.blockEventTable).toEventMessage()).toList();
  }

  Stream<List<EventMessage>> watchBlockedByUsersEvents(String currentUserMasterPubkey) {
    return _blockedByUsersQuery(currentUserMasterPubkey).watch().map(
          (rows) => rows.map((row) => row.readTable(db.blockEventTable).toEventMessage()).toList(),
        );
  }
}
