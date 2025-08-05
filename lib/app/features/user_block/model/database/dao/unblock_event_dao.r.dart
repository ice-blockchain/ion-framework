// SPDX-License-Identifier: ice License 1.0

part of '../block_user_database.m.dart';

@riverpod
UnblockEventDao unblockEventDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UnblockEventDao(ref.watch(blockedUsersDatabaseProvider));
}

@DriftAccessor(tables: [UnblockEventTable])
class UnblockEventDao extends DatabaseAccessor<BlockUserDatabase> with _$UnblockEventDaoMixin {
  UnblockEventDao(super.db);

  Future<void> add(EventReference eventReference) async {
    await into(db.unblockEventTable).insert(
      UnblockEventTableCompanion(eventReference: Value(eventReference)),
      mode: InsertMode.insertOrReplace,
    );
  }
}
