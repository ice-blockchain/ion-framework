// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:drift/native.dart';
import 'package:ion_connect_cache/src/database/ion_connect_cache_database.d.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';
import 'package:ion_connect_cache/src/extensions/event_message_cache_db_model.dart';
import 'package:ion_connect_cache/src/models/database_cache_entry.dart';
import 'package:ion_connect_cache/src/service/ion_connect_cache_service.dart';
import 'package:nostr_dart/nostr_dart.dart';

part 'ion_connect_cache_service_drift_impl.d.g.dart';

@DriftAccessor(tables: [EventMessagesTable])
class IonConnectCacheServiceDriftImpl extends DatabaseAccessor<IONConnectCacheDatabase>
    with _$IonConnectCacheServiceDriftImplMixin
    implements IonConnectCacheService {
  IonConnectCacheServiceDriftImpl({required IONConnectCacheDatabase db}) : super(db);

  IonConnectCacheServiceDriftImpl.persistent(String path)
    : super(IONConnectCacheDatabase(NativeDatabase.createInBackground(File(path))));

  @override
  Future<EventMessage> save(
    ({String masterPubkey, String eventReference, EventMessage eventMessage}) value,
  ) {
    final dbModel = IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
      masterPubkey: value.masterPubkey,
      eventMessage: value.eventMessage,
      eventReference: value.eventReference,
    );

    return into(eventMessagesTable).insertOnConflictUpdate(dbModel).then((_) => value.eventMessage);
  }

  @override
  Future<List<EventMessage>> saveAll(
    List<({String masterPubkey, String eventReference, EventMessage eventMessage})> values,
  ) async {
    final dbModels = values.map((value) {
      return IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
        masterPubkey: value.masterPubkey,
        eventMessage: value.eventMessage,
        eventReference: value.eventReference,
      );
    });

    await batch((batch) {
      batch.insertAllOnConflictUpdate(eventMessagesTable, dbModels);
    });

    return values.map((e) => e.eventMessage).toList();
  }

  @override
  Future<DatabaseCacheEntry?> get(String eventReference) async {
    final dbModel =
        await (select(eventMessagesTable)
              ..limit(1)
              ..where((tbl) => tbl.eventReference.equals(eventReference)))
            .getSingleOrNull();

    if (dbModel == null) {
      return null;
    }
    return DatabaseCacheEntry(
      eventMessage: dbModel.toEventMessage(),
      insertedAt: DateTime.fromMillisecondsSinceEpoch(dbModel.insertedAt),
    );
  }

  @override
  Future<List<DatabaseCacheEntry?>> getAllFiltered({
    required String keyword,
    List<int> kinds = const [],
    List<String> eventReferences = const [],
  }) {
    final q = '%${keyword.toLowerCase()}%';
    final kindFilter = kinds.isNotEmpty
        ? (eventMessagesTable.kind.isIn(kinds))
        : const Constant(true);
    final referenceFilter = eventReferences.isNotEmpty
        ? (eventMessagesTable.eventReference.isIn(eventReferences))
        : const Constant(true);

    return (select(eventMessagesTable)
          ..where(
            (tbl) =>
                (tbl.content.lower().like(q) | tbl.tags.jsonExtract(r'$[*][*]').equals(keyword)) &
                kindFilter &
                referenceFilter,
          )
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get()
        .then(
          (rows) => rows.map((row) {
            DatabaseCacheEntry(
              eventMessage: row.toEventMessage(),
              insertedAt: DateTime.fromMillisecondsSinceEpoch(row.insertedAt),
            );
          }).toList(),
        );
  }

  @override
  Future<List<DatabaseCacheEntry?>> getAll(List<String> eventReferences) {
    return (select(
      eventMessagesTable,
    )..where((tbl) => tbl.eventReference.isIn(eventReferences))).get().then(
      (rows) => rows.map((row) {
        return DatabaseCacheEntry(
          eventMessage: row.toEventMessage(),
          insertedAt: DateTime.fromMillisecondsSinceEpoch(row.insertedAt),
        );
      }).toList(),
    );
  }

  @override
  Stream<List<EventMessage>> watchAll(List<String> eventReferences) {
    return (select(eventMessagesTable)..where((tbl) => tbl.eventReference.isIn(eventReferences)))
        .watch()
        .map((rows) => rows.map((row) => row.toEventMessage()).toList());
  }

  @override
  Future<int> remove(String eventReference) async {
    return (delete(
      eventMessagesTable,
    )..where((tbl) => tbl.eventReference.equals(eventReference))).go();
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
