// SPDX-License-Identifier: ice License 1.0

part of '../user_archive_database.m.dart';

@riverpod
UserArchiveEventDao userArchiveEventDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserArchiveEventDao(ref.watch(userArchiveDatabaseProvider));
}

@DriftAccessor(tables: [UserArchiveEventTable])
class UserArchiveEventDao extends DatabaseAccessor<UserArchiveDatabase>
    with _$UserArchiveEventDaoMixin {
  UserArchiveEventDao(super.db);

  Future<void> add(EventMessage event) async {
    if (event.kind != UserArchiveEntity.kind) return;

    final eventReference = UserArchiveEntity.fromEventMessage(event).toEventReference();
    final dbModel = event.toArchiveEventDbModel(eventReference);

    await into(db.userArchiveEventTable).insert(dbModel, mode: InsertMode.insertOrReplace);
  }

  Future<void> remove(ImmutableEventReference eventReference) async {
    final query = delete(userArchiveEventTable)
      ..where((t) => t.eventReference.equalsValue(eventReference));
    await query.go();
  }

  Stream<EventMessage?> watchLatestArchiveEvent() {
    final query = select(userArchiveEventTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    return query.watch().map(
          (rows) => rows.map((row) {
            return row.toEventMessage();
          }).firstOrNull,
        );
  }

  Future<bool> hasAnyArchiveEvent() async {
    final query = select(userArchiveEventTable)..limit(1);
    final row = await query.getSingleOrNull();
    return row != null;
  }
}
