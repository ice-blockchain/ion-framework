// SPDX-License-Identifier: ice License 1.0

part of '../event_messages_database.m.dart';

@Riverpod(keepAlive: true)
EventMessagesDao eventMessagesDao(Ref ref) =>
    EventMessagesDao(db: ref.watch(eventMessagesDatabaseProvider));

@DriftAccessor(tables: [EventMessagesTable])
class EventMessagesDao extends DatabaseAccessor<EventMessagesDatabase>
    with _$EventMessagesDaoMixin {
  EventMessagesDao({required EventMessagesDatabase db}) : super(db);

  Future<void> insert(EventMessageDbModel eventMessage) async {
    await into(db.eventMessagesTable).insert(eventMessage, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertAll(List<EventMessageDbModel> eventMessages) {
    return batch((batch) {
      batch.insertAll(db.eventMessagesTable, eventMessages, mode: InsertMode.insertOrReplace);
    });
  }

  Stream<EventMessageDbModel?> watch(EventReference eventReference) {
    final query = select(db.eventMessagesTable)
      ..where((event) => event.eventReference.equalsValue(eventReference));

    return query.watchSingleOrNull();
  }

  Stream<List<EventMessageDbModel>> watchAll(List<EventReference> eventReferences) {
    final query = select(db.eventMessagesTable)
      ..where((event) => event.eventReference.isInValues(eventReferences));

    return query.watch();
  }

  Future<List<EventMessageDbModel>> get(List<EventReference> eventReferences) {
    final query = select(db.eventMessagesTable)
      ..where((event) => event.eventReference.isInValues(eventReferences));

    return query.get();
  }

  Future<List<EventMessageDbModel>> getFiltered({
    required String query,
    List<int>? kinds,
    List<EventReference>? eventReferences,
  }) {
    final pattern = '%${query.toLowerCase()}%';
    final filteredQuery = select(db.eventMessagesTable);

    if (eventReferences != null) {
      filteredQuery.where((tbl) => tbl.eventReference.isInValues(eventReferences));
    }

    if (kinds != null) {
      filteredQuery.where((tbl) => tbl.kind.isIn(kinds));
    }

    filteredQuery.where((tbl) => tbl.content.like(pattern) | tbl.tags.like(pattern));

    return filteredQuery.get();
  }

  Future<Set<EventReference>> nonExistingReferences(Set<EventReference> eventReferences) async {
    final query = select(db.eventMessagesTable)
      ..where((event) => event.eventReference.isInValues(eventReferences));

    final existingReferences = (await query.map((message) => message.eventReference).get()).toSet();
    return eventReferences.difference(existingReferences);
  }

  Future<void> removeAll(List<EventReference> eventReferences) {
    final query = delete(db.eventMessagesTable)
      ..where((event) => event.eventReference.isInValues(eventReferences));

    return query.go();
  }
}
