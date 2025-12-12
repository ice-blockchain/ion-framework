// SPDX-License-Identifier: ice License 1.0

part of '../user_mute_database.m.dart';

@riverpod
UserMuteEventDao userMuteEventDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserMuteEventDao(ref.watch(userMuteDatabaseProvider));
}

@DriftAccessor(tables: [UserMuteEventTable])
class UserMuteEventDao extends DatabaseAccessor<UserMuteDatabase> with _$UserMuteEventDaoMixin {
  UserMuteEventDao(super.db);

  Future<void> add(EventMessage event) async {
    if (event.kind != UserMuteEntity.kind) return;

    final eventReference = UserMuteEntity.fromEventMessage(event).toEventReference();
    final dbModel = event.toMuteEventDbModel(eventReference);

    await into(db.userMuteEventTable).insert(dbModel, mode: InsertMode.insertOrReplace);
  }

  Future<void> remove(ImmutableEventReference eventReference) async {
    final query = delete(userMuteEventTable)
      ..where((t) => t.eventReference.equalsValue(eventReference));
    await query.go();
  }

  Stream<EventMessage?> watchLatestMuteEvent() {
    final query = select(userMuteEventTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return row.toEventMessage();
    });
  }

  Future<bool> hasAnyMuteEvent() async {
    final query = select(userMuteEventTable)..limit(1);
    final row = await query.getSingleOrNull();
    return row != null;
  }
}
