// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ion_connect_cache/src/database/ion_connect_cache_database.d.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';
import 'package:ion_connect_cache/src/extensions/event_message_cache_db_model.dart';
import 'package:ion_connect_cache/src/service/ion_connect_cache_service.dart';
import 'package:nostr_dart/nostr_dart.dart';

part 'ion_connect_cache_service_drift_impl.d.g.dart';

@DriftAccessor(tables: [EventMessagesTable])
class IonConnectCacheServiceDriftImpl extends DatabaseAccessor<IONConnectCacheDatabase>
    with _$IonConnectCacheServiceDriftImplMixin
    implements IonConnectCacheService {
  IonConnectCacheServiceDriftImpl({required IONConnectCacheDatabase db}) : super(db);

  IonConnectCacheServiceDriftImpl.inMemory()
    : super(
        IONConnectCacheDatabase(
          NativeDatabase.memory(setup: (database) => database.execute('PRAGMA foreign_keys = ON;')),
        ),
      );

  IonConnectCacheServiceDriftImpl.persistent(String path)
    : super(IONConnectCacheDatabase(NativeDatabase.createInBackground(File(path))));

  @override
  Future<EventMessage> save(
    (String masterPubkey, String eventReference, EventMessage eventMessage) value,
  ) {
    final dbModel = IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
      masterPubkey: value.$1,
      eventReference: value.$2,
      eventMessage: value.$3,
    );

    return into(eventMessagesTable).insertOnConflictUpdate(dbModel).then((_) => value.$3);
  }

  @override
  Future<List<EventMessage>> saveAll(
    List<(String masterPubkey, String eventReference, EventMessage eventMessage)> values,
  ) async {
    final dbModels = values.map((value) {
      return IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
        masterPubkey: value.$1,
        eventReference: value.$2,
        eventMessage: value.$3,
      );
    });

    await batch((batch) {
      batch.insertAllOnConflictUpdate(eventMessagesTable, dbModels);
    });

    return values.map((e) => e.$3).toList();
  }

  @override
  Future<EventMessage?> get(String eventReference, {DateTime? after}) async {
    final expirationExpression = after != null
        ? eventMessagesTable.insertedAt.isBiggerThanValue(after.millisecondsSinceEpoch)
        : const Constant(true);

    final dbModel =
        await (select(eventMessagesTable)
              ..limit(1)
              ..where((tbl) => tbl.id.equals(eventReference) & expirationExpression))
            .getSingleOrNull();

    return dbModel?.toEventMessage();
  }

  @override
  Future<List<EventMessage>> getAllFiltered({
    required String query,
    List<int> kinds = const [],
    List<String> eventReferences = const [],
  }) {
    final q = '%${query.toLowerCase()}%';
    final kindFilter = kinds.isNotEmpty ? (eventMessagesTable.kind.isIn(kinds)) : const Constant(true);
    final referenceFilter = eventReferences.isNotEmpty
        ? (eventMessagesTable.eventReference.isIn(eventReferences))
        : const Constant(true);

    return (select(eventMessagesTable)
          ..where(
            (tbl) =>
                (tbl.content.lower().like(q) | tbl.tags.lower().like(q)) &
                kindFilter &
                referenceFilter,
          )
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get()
        .then((rows) => rows.map((row) => row.toEventMessage()).toList());
  }

  @override
  Future<List<EventMessage>> getAll(List<String> eventReferences) {
    return (select(eventMessagesTable)..where((tbl) => tbl.eventReference.isIn(eventReferences)))
        .get()
        .then((rows) => rows.map((row) => row.toEventMessage()).toList());
  }

  @override
  Future<Set<String>> getAllNonExistingReferences(Set<String> eventReferences) async {
    final query = select(db.eventMessagesTable)
      ..where((event) => event.eventReference.isIn(eventReferences));

    final existingReferences = (await query.map((message) => message.eventReference).get()).toSet();
    return eventReferences.difference(existingReferences);
  }

  @override
  Stream<List<EventMessage>> watchAll(List<String> eventReferences) {
    return (select(eventMessagesTable)..where((tbl) => tbl.eventReference.isIn(eventReferences)))
        .watch()
        .map((rows) => rows.map((row) => row.toEventMessage()).toList());
  }

  @override
  Future<int> remove(String id) async {
    return (delete(eventMessagesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<int> clearDatabase() {
    return delete(eventMessagesTable).go();
  }

  @override
  Future<int> removeAll(List<String> eventReferences) {
    return (delete(
      eventMessagesTable,
    )..where((tbl) => tbl.eventReference.isIn(eventReferences))).go();
  }
}
