// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';
import 'package:ion_connect_cache/src/database/ion_connect_cache_database.d.dart';
import 'package:ion_connect_cache/src/database/tables/event_messages_table.d.dart';
import 'package:ion_connect_cache/src/extensions/event_message.dart';
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

  @override
  Future<EventMessage?> save(({String cacheKey, EventMessage eventMessage}) value) async {
    final masterPubkey = value.eventMessage.masterPubkey;

    if (masterPubkey != null) {
      final dbModel = IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
        masterPubkey: masterPubkey,
        cacheKey: value.cacheKey,
        eventMessage: value.eventMessage,
      );

      return into(
        eventMessagesTable,
      ).insertOnConflictUpdate(dbModel).then((_) => value.eventMessage);
    }

    return null;
  }

  @override
  Future<List<EventMessage>> saveAll(
    List<({String cacheKey, EventMessage eventMessage})> values,
  ) async {
    final dbModels = values.map((value) {
      final masterPubkey = value.eventMessage.masterPubkey;

      if (masterPubkey != null) {
        return IonConnectCacheEventMessageDbModelExtensions.fromEventMessage(
          cacheKey: value.cacheKey,
          eventMessage: value.eventMessage,
          masterPubkey: value.eventMessage.masterPubkey!,
        );
      }

      return null;
    });

    await batch((batch) {
      batch.insertAllOnConflictUpdate(eventMessagesTable, dbModels.nonNulls);
    });

    return dbModels.nonNulls.map((e) => e.toEventMessage()).toList();
  }

  @override
  Future<DatabaseCacheEntry?> get(String cacheKey) async {
    final dbModel =
        await (select(eventMessagesTable)
              ..limit(1)
              ..where((tbl) => tbl.cacheKey.equals(cacheKey)))
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
  Future<List<DatabaseCacheEntry>> getAllFiltered({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
  }) async {
    final conditions = <Expression<bool>>[];

    final q = keyword != null ? '%${keyword.toLowerCase()}%' : null;

    if (kinds.isNotEmpty) {
      conditions.add(eventMessagesTable.kind.isIn(kinds));
    }
    if (cacheKeys.isNotEmpty) {
      conditions.add(eventMessagesTable.cacheKey.isIn(cacheKeys));
    }
    if (keyword != null) {
      conditions.add(
        eventMessagesTable.content.lower().like(q!) |
            eventMessagesTable.tags.jsonExtract(r'$[*][*]').equals(keyword),
      );
    }

    final query = select(eventMessagesTable);
    if (conditions.isNotEmpty) {
      query.where((tbl) => conditions.reduce((previous, next) => previous & next));
    }

    final rows = await query.get();
    return rows
        .map(
          (row) => DatabaseCacheEntry(
            eventMessage: row.toEventMessage(),
            insertedAt: DateTime.fromMillisecondsSinceEpoch(row.insertedAt),
          ),
        )
        .toList();
  }

  @override
  Stream<EventMessage?> watch(String cacheKey) {
    return (select(eventMessagesTable)
          ..where((tbl) => tbl.cacheKey.equals(cacheKey))
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row?.toEventMessage());
  }

  @override
  Stream<List<EventMessage>> watchAll({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    List<String> masterPubkeys = const [],
  }) {
    final query = _buildFilteredQuery(
      kinds: kinds,
      keyword: keyword,
      cacheKeys: cacheKeys,
      masterPubkeys: masterPubkeys,
    );
    return query.watch().map((rows) => rows.map((row) => row.toEventMessage()).toList());
  }

  @override
  Future<int> clearDatabase() {
    return delete(eventMessagesTable).go();
  }

  @override
  Future<int> remove(String cacheKey) {
    return (delete(eventMessagesTable)..where((tbl) => tbl.cacheKey.equals(cacheKey))).go();
  }

  @override
  Future<int> removeAll({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    List<String> masterPubkeys = const [],
  }) async {
    final conditions = _buildConditions(
      keyword: keyword,
      kinds: kinds,
      cacheKeys: cacheKeys,
      masterPubkeys: masterPubkeys,
    );
    final deleteQuery = delete(eventMessagesTable);
    if (conditions.isNotEmpty) {
      deleteQuery.where((tbl) => conditions.reduce((previous, next) => previous & next));
    }
    return deleteQuery.go();
  }

  // Shared conditions builder for filtering queries
  List<Expression<bool>> _buildConditions({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    List<String> masterPubkeys = const [],
  }) {
    final conditions = <Expression<bool>>[];
    final q = keyword != null ? '%${keyword.toLowerCase()}%' : null;

    if (kinds.isNotEmpty) {
      conditions.add(eventMessagesTable.kind.isIn(kinds));
    }
    if (cacheKeys.isNotEmpty) {
      conditions.add(eventMessagesTable.cacheKey.isIn(cacheKeys));
    }
    if (masterPubkeys.isNotEmpty) {
      conditions.add(eventMessagesTable.masterPubkey.isIn(masterPubkeys));
    }
    if (keyword != null) {
      conditions.add(
        eventMessagesTable.content.lower().like(q!) |
            eventMessagesTable.tags.jsonExtract(r'$[*][*]').equals(keyword),
      );
    }
    return conditions;
  }

  // Shared query builder for getAllFiltered and watchAll
  SimpleSelectStatement<$EventMessagesTableTable, EventMessageCacheDbModel> _buildFilteredQuery({
    String? keyword,
    List<int> kinds = const [],
    List<String> cacheKeys = const [],
    List<String> masterPubkeys = const [],
  }) {
    final conditions = _buildConditions(
      keyword: keyword,
      kinds: kinds,
      cacheKeys: cacheKeys,
      masterPubkeys: masterPubkeys,
    );
    final query = select(eventMessagesTable);
    if (conditions.isNotEmpty) {
      query.where((tbl) => conditions.reduce((previous, next) => previous & next));
    }
    return query;
  }
}
